import Foundation

enum ScopeThemeProviderError: LocalizedError {
    case missingAPIKey
    case invalidBaseURL
    case invalidResponse
    case missingStructuredOutput
    case invalidThemePayload
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add an OpenAI API key before requesting generated scope looks."
        case .invalidBaseURL:
            return "The configured scope theme provider URL is invalid."
        case .invalidResponse:
            return "The provider returned an unexpected response."
        case .missingStructuredOutput:
            return "The provider did not return a structured scope theme."
        case .invalidThemePayload:
            return "The generated scope theme did not pass validation."
        case let .requestFailed(message):
            return message
        }
    }
}

struct OpenAIScopeThemeProvider {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    var isConfigured: Bool {
        configuration != nil
    }

    var modelID: String? {
        configuration?.modelID
    }

    func generateRecipe(for scope: ScopeRecord) async throws -> ScopeThemeRecipe {
        guard let configuration else {
            throw ScopeThemeProviderError.missingAPIKey
        }

        var request = URLRequest(url: configuration.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try requestBody(for: scope, modelID: configuration.modelID)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScopeThemeProviderError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data) {
                throw ScopeThemeProviderError.requestFailed(apiError.error.message)
            }
            throw ScopeThemeProviderError.requestFailed("Theme request failed with status \(httpResponse.statusCode).")
        }

        let envelope = try JSONDecoder().decode(OpenAIResponseEnvelope.self, from: data)
        if let refusal = envelope.refusalText {
            throw ScopeThemeProviderError.requestFailed(refusal)
        }

        guard let outputText = envelope.outputText else {
            throw ScopeThemeProviderError.missingStructuredOutput
        }

        let payload = try JSONDecoder().decode(ScopeThemeRecipePayload.self, from: Data(outputText.utf8))
        return try payload.validated(modelID: configuration.modelID)
    }

    private var configuration: ScopeThemeProviderConfiguration? {
        ScopeThemeProviderConfiguration.current
    }

    private func requestBody(for scope: ScopeRecord, modelID: String) throws -> Data {
        let schema: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "motif": [
                    "type": "string",
                    "enum": ScopeArtMotif.allCases.map(\.rawValue),
                ],
                "heroStyle": [
                    "type": "string",
                    "enum": ScopeHeroStyle.allCases.map(\.rawValue),
                ],
                "sectionLayout": [
                    "type": "string",
                    "enum": ScopeSectionLayout.allCases.map(\.rawValue),
                ],
                "headerLabel": [
                    "type": "string",
                    "description": "A calm 1-3 word label that frames the scope without sounding technical.",
                ],
                "pageCanvasHex": [
                    "type": "string",
                    "description": "Six-digit hex color, no hash.",
                ],
                "surfaceHex": [
                    "type": "string",
                    "description": "Six-digit hex color, no hash.",
                ],
                "heroFillHex": [
                    "type": "string",
                    "description": "Six-digit hex color, no hash.",
                ],
                "accentHex": [
                    "type": "string",
                    "description": "Six-digit hex color, no hash.",
                ],
                "patternHex": [
                    "type": "string",
                    "description": "Six-digit hex color, no hash.",
                ],
                "primaryTextHex": [
                    "type": "string",
                    "description": "Six-digit hex color, no hash.",
                ],
            ],
            "required": [
                "motif",
                "heroStyle",
                "sectionLayout",
                "headerLabel",
                "pageCanvasHex",
                "surfaceHex",
                "heroFillHex",
                "accentHex",
                "patternHex",
                "primaryTextHex",
            ],
        ]

        let body: [String: Any] = [
            "model": modelID,
            "store": false,
            "instructions": """
            You generate scope-specific interface themes for an iPhone app called Scope.
            The product should feel calm, editorial, trustworthy, and easy to re-enter.
            Keep the result restrained and legible.
            Never produce flashy, neon, futuristic, or dashboard-like looks.
            Choose the most fitting motif, hero style, section layout, and palette for the scope.
            Return only JSON matching the schema.
            """,
            "input": [
                [
                    "role": "user",
                    "content": scopePrompt(for: scope),
                ],
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "scope_theme_recipe",
                    "strict": true,
                    "schema": schema,
                ],
            ],
        ]

        return try JSONSerialization.data(withJSONObject: body)
    }

    private func scopePrompt(for scope: ScopeRecord) -> String {
        let categories = scope.categoryPreview.joined(separator: ", ")
        let signals = scope.cardSignals.prefix(2).map(\.text).joined(separator: "; ")
        let memoryHints = scope.recentMemory.prefix(2).map(\.title).joined(separator: "; ")

        return """
        Design a stable scope look for this context.

        Scope title: \(scope.title)
        Summary: \(scope.summary)
        Categories: \(categories.isEmpty ? "None yet" : categories)
        Signals: \(signals.isEmpty ? "None" : signals)
        Recent memory hints: \(memoryHints.isEmpty ? "None yet" : memoryHints)

        Available motif meanings:
        - storyboard: product thinking, creative work, planning, concepts
        - transit: travel, movement, logistics, routes
        - strength: training, routines, repetition, structure
        - constellation: reflective, research, synthesis, mapping ideas
        - wave: personal, soft, ongoing, ambient subjects

        Available hero styles:
        - editorial: bold title plus overview
        - itinerary: next-step framing for plan-heavy scopes
        - ledger: structured, grounded, regimen-like framing

        Available section layouts:
        - focusFirst: orient first, then memory
        - memoryFirst: recent memory before focus summary

        Color rules:
        - use muted, intentional palettes
        - avoid pure black and pure white
        - primary text must remain highly readable on the canvas and surface
        - hero fill can be dark or light, but should still feel calm
        """
    }
}

private struct ScopeThemeProviderConfiguration {
    let apiKey: String
    let modelID: String
    let endpoint: URL

    static var current: ScopeThemeProviderConfiguration? {
        let environment = ProcessInfo.processInfo.environment
        guard let apiKey = environment["OPENAI_API_KEY"]?.trimmedNonEmpty else {
            return nil
        }

        let modelID = environment["SCOPE_THEME_MODEL"]?.trimmedNonEmpty ?? "gpt-5.4-mini"
        let baseURLString =
            environment["SCOPE_THEME_BASE_URL"]?.trimmedNonEmpty ??
            environment["OPENAI_BASE_URL"]?.trimmedNonEmpty ??
            "https://api.openai.com"

        guard let baseURL = URL(string: baseURLString),
              let endpoint = endpointURL(from: baseURL) else {
            return nil
        }

        return ScopeThemeProviderConfiguration(apiKey: apiKey, modelID: modelID, endpoint: endpoint)
    }

    private static func endpointURL(from baseURL: URL) -> URL? {
        let path = baseURL.path

        if path.hasSuffix("/v1/responses") {
            return baseURL
        }

        if path.hasSuffix("/v1") {
            return baseURL.appending(path: "responses")
        }

        if path.isEmpty || path == "/" {
            return baseURL.appending(path: "v1").appending(path: "responses")
        }

        return baseURL.appending(path: "responses")
    }
}

private struct ScopeThemeRecipePayload: Decodable {
    let motif: ScopeArtMotif
    let heroStyle: ScopeHeroStyle
    let sectionLayout: ScopeSectionLayout
    let headerLabel: String
    let pageCanvasHex: String
    let surfaceHex: String
    let heroFillHex: String
    let accentHex: String
    let patternHex: String
    let primaryTextHex: String

    func validated(modelID: String) throws -> ScopeThemeRecipe {
        let normalizedHeader = headerLabel.condensedWhitespace
        guard !normalizedHeader.isEmpty else {
            throw ScopeThemeProviderError.invalidThemePayload
        }

        let title = normalizedHeader.split(separator: " ").prefix(3).joined(separator: " ")

        guard let pageCanvasHex = pageCanvasHex.normalizedHexColor,
              let surfaceHex = surfaceHex.normalizedHexColor,
              let heroFillHex = heroFillHex.normalizedHexColor,
              let accentHex = accentHex.normalizedHexColor,
              let patternHex = patternHex.normalizedHexColor,
              let primaryTextHex = primaryTextHex.normalizedHexColor else {
            throw ScopeThemeProviderError.invalidThemePayload
        }

        let canvasColor = ScopeHexColor(hex: pageCanvasHex)
        let surfaceColor = ScopeHexColor(hex: surfaceHex)
        let primaryTextColor = ScopeHexColor(hex: primaryTextHex)

        guard canvasColor.contrastRatio(with: primaryTextColor) >= 4.5,
              surfaceColor.contrastRatio(with: primaryTextColor) >= 4.5 else {
            throw ScopeThemeProviderError.invalidThemePayload
        }

        return ScopeThemeRecipe(
            motif: motif,
            heroStyle: heroStyle,
            sectionLayout: sectionLayout,
            headerLabel: title,
            pageCanvasHex: pageCanvasHex,
            surfaceHex: surfaceHex,
            heroFillHex: heroFillHex,
            accentHex: accentHex,
            patternHex: patternHex,
            primaryTextHex: primaryTextHex,
            providerModelID: modelID,
            generatedAt: .now
        )
    }
}

private struct OpenAIResponseEnvelope: Decodable {
    let output: [OpenAIResponseItem]

    var outputText: String? {
        let content = output.flatMap { $0.content ?? [] }
        let matchingContent = content.filter { item in
            item.type == "output_text" || item.type == "text"
        }
        let pieces = matchingContent.compactMap { item in
            item.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .filter { !$0.isEmpty }

        guard !pieces.isEmpty else { return nil }
        return pieces.joined(separator: "\n")
    }

    var refusalText: String? {
        let content = output.flatMap { $0.content ?? [] }
        let refusal = content.first { $0.type == "refusal" }?.refusal
        return refusal?.trimmedNonEmpty
    }
}

private struct OpenAIResponseItem: Decodable {
    let content: [OpenAIResponseContent]?
}

private struct OpenAIResponseContent: Decodable {
    let type: String
    let text: String?
    let refusal: String?
}

private struct OpenAIErrorEnvelope: Decodable {
    let error: OpenAIErrorPayload
}

private struct OpenAIErrorPayload: Decodable {
    let message: String
}

private struct ScopeHexColor {
    let red: Double
    let green: Double
    let blue: Double

    init(hex: String) {
        let scanner = Scanner(string: hex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        red = Double((value & 0xFF0000) >> 16) / 255.0
        green = Double((value & 0x00FF00) >> 8) / 255.0
        blue = Double(value & 0x0000FF) / 255.0
    }

    func contrastRatio(with other: ScopeHexColor) -> Double {
        let lhs = relativeLuminance
        let rhs = other.relativeLuminance
        let lighter = max(lhs, rhs)
        let darker = min(lhs, rhs)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private var relativeLuminance: Double {
        let channels = [red, green, blue].map { channel -> Double in
            if channel <= 0.03928 {
                return channel / 12.92
            }
            return pow((channel + 0.055) / 1.055, 2.4)
        }

        return (0.2126 * channels[0]) + (0.7152 * channels[1]) + (0.0722 * channels[2])
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var condensedWhitespace: String {
        split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    var normalizedHexColor: String? {
        let candidate = replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard candidate.range(of: "^[0-9A-F]{6}$", options: .regularExpression) != nil else {
            return nil
        }

        return candidate
    }
}
