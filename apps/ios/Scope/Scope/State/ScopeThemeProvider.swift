import Foundation

enum ScopeThemeProviderError: LocalizedError {
    case missingConfiguredRoute
    case missingCredential(String)
    case invalidBaseURL(String)
    case invalidResponse
    case missingStructuredOutput
    case invalidThemePayload
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguredRoute:
            return "Configure a quick or theme model before requesting generated scope looks."
        case let .missingCredential(message):
            return message
        case let .invalidBaseURL(urlString):
            return "The configured provider URL is invalid: \(urlString)"
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

struct ScopeProviderRuntimeState {
    let credentials: [ProviderCredentialRecord]
    let connections: [ProviderConnectionRecord]
    let modelProfiles: [ProviderModelProfileRecord]
    let routeAssignments: [ProviderRouteAssignmentRecord]

    static var current: ScopeProviderRuntimeState {
        bootstrap(from: ProcessInfo.processInfo.environment)
    }

    static func bootstrap(from environment: [String: String]) -> ScopeProviderRuntimeState {
        var credentials: [ProviderCredentialRecord] = []
        var connections: [ProviderConnectionRecord] = []
        var modelProfiles: [ProviderModelProfileRecord] = []
        var routeAssignments: [ProviderRouteAssignmentRecord] = []

        func appendProvider(
            kind: ProviderKind,
            credentialEnvVar: String,
            endpointEnvVars: [String],
            lightweightModelEnvVar: String,
            lightweightModelID: String,
            heavyweightModelEnvVar: String,
            heavyweightModelID: String,
            capabilities: Set<ProviderModelCapability>
        ) {
            guard environment[credentialEnvVar]?.trimmedNonEmpty != nil else {
                return
            }

            let endpointOverride = endpointEnvVars.compactMap { environment[$0]?.trimmedNonEmpty }.first

            let credential = ProviderCredentialRecord(
                displayName: "\(kind.displayName) key",
                storageKind: .environmentVariable,
                secretReference: credentialEnvVar
            )

            let connection = ProviderConnectionRecord(
                providerKind: kind,
                displayName: kind.displayName,
                endpointOverride: endpointOverride,
                credentialID: credential.id
            )

            let lightweightProfile = ProviderModelProfileRecord(
                connectionID: connection.id,
                displayName: "\(kind.displayName) quick",
                modelID: environment[lightweightModelEnvVar]?.trimmedNonEmpty ?? lightweightModelID,
                tier: .lightweight,
                capabilities: capabilities
            )

            let heavyweightProfile = ProviderModelProfileRecord(
                connectionID: connection.id,
                displayName: "\(kind.displayName) deep",
                modelID: environment[heavyweightModelEnvVar]?.trimmedNonEmpty ?? heavyweightModelID,
                tier: .heavyweight,
                capabilities: capabilities
            )

            credentials.append(credential)
            connections.append(connection)
            modelProfiles.append(lightweightProfile)
            modelProfiles.append(heavyweightProfile)
        }

        appendProvider(
            kind: .openAI,
            credentialEnvVar: "OPENAI_API_KEY",
            endpointEnvVars: ["SCOPE_OPENAI_BASE_URL", "SCOPE_THEME_BASE_URL", "OPENAI_BASE_URL"],
            lightweightModelEnvVar: "SCOPE_OPENAI_LIGHT_MODEL",
            lightweightModelID: "gpt-5.4-mini",
            heavyweightModelEnvVar: "SCOPE_OPENAI_HEAVY_MODEL",
            heavyweightModelID: "gpt-5.4",
            capabilities: [.structuredOutputs, .imageInput, .largeContext]
        )

        appendProvider(
            kind: .anthropic,
            credentialEnvVar: "ANTHROPIC_API_KEY",
            endpointEnvVars: ["SCOPE_ANTHROPIC_BASE_URL", "ANTHROPIC_BASE_URL"],
            lightweightModelEnvVar: "SCOPE_ANTHROPIC_LIGHT_MODEL",
            lightweightModelID: "claude-3-5-haiku-latest",
            heavyweightModelEnvVar: "SCOPE_ANTHROPIC_HEAVY_MODEL",
            heavyweightModelID: "claude-sonnet-4-20250514",
            capabilities: [.structuredOutputs, .clientToolUse, .imageInput, .largeContext]
        )

        appendProvider(
            kind: .gemini,
            credentialEnvVar: "GEMINI_API_KEY",
            endpointEnvVars: ["SCOPE_GEMINI_BASE_URL", "GEMINI_BASE_URL"],
            lightweightModelEnvVar: "SCOPE_GEMINI_LIGHT_MODEL",
            lightweightModelID: "gemini-2.5-flash-lite",
            heavyweightModelEnvVar: "SCOPE_GEMINI_HEAVY_MODEL",
            heavyweightModelID: "gemini-2.5-pro",
            capabilities: [.structuredOutputs, .imageInput, .largeContext]
        )

        func connection(for kind: ProviderKind) -> ProviderConnectionRecord? {
            connections.first { $0.providerKind == kind && $0.isEnabled }
        }

        func defaultProfile(for kind: ProviderKind, tier: ProviderModelTier) -> ProviderModelProfileRecord? {
            guard let connection = connection(for: kind) else {
                return nil
            }

            return modelProfiles.first {
                $0.connectionID == connection.id &&
                $0.tier == tier &&
                $0.isEnabled
            }
        }

        func makeCustomProfile(
            providerKind: ProviderKind,
            modelID: String,
            route: InferenceRouteKind
        ) -> ProviderModelProfileRecord? {
            guard let connection = connection(for: providerKind) else {
                return nil
            }

            if let existingProfile = modelProfiles.first(where: {
                $0.connectionID == connection.id &&
                $0.modelID == modelID &&
                $0.isEnabled
            }) {
                return existingProfile
            }

            let capabilities = defaultProfile(for: providerKind, tier: .lightweight)?.capabilities ?? [.structuredOutputs]
            let profile = ProviderModelProfileRecord(
                connectionID: connection.id,
                displayName: "\(providerKind.displayName) \(route.displayName.lowercased())",
                modelID: modelID,
                tier: .custom,
                capabilities: capabilities
            )

            modelProfiles.append(profile)
            return profile
        }

        func explicitProfile(for route: InferenceRouteKind, defaultTier: ProviderModelTier) -> ProviderModelProfileRecord? {
            guard let providerKind = environment["SCOPE_\(route.environmentPrefix)_PROVIDER"]?.providerKindValue else {
                return nil
            }

            if let modelID = environment["SCOPE_\(route.environmentPrefix)_MODEL"]?.trimmedNonEmpty {
                return makeCustomProfile(providerKind: providerKind, modelID: modelID, route: route)
                    ?? defaultProfile(for: providerKind, tier: defaultTier)
            }

            return defaultProfile(for: providerKind, tier: defaultTier)
        }

        func legacyOpenAIThemeProfile() -> ProviderModelProfileRecord? {
            guard let legacyModelID = environment["SCOPE_THEME_MODEL"]?.trimmedNonEmpty else {
                return nil
            }

            return makeCustomProfile(
                providerKind: .openAI,
                modelID: legacyModelID,
                route: .themeGeneration
            ) ?? defaultProfile(for: .openAI, tier: .lightweight)
        }

        func firstAvailableProfile(for tier: ProviderModelTier) -> ProviderModelProfileRecord? {
            [ProviderKind.openAI, .anthropic, .gemini]
                .compactMap { defaultProfile(for: $0, tier: tier) }
                .first
        }

        let quickProfile = explicitProfile(for: .quick, defaultTier: .lightweight)
            ?? firstAvailableProfile(for: .lightweight)
        let deepProfile = explicitProfile(for: .deep, defaultTier: .heavyweight)
            ?? firstAvailableProfile(for: .heavyweight)
        let themeProfile = explicitProfile(for: .themeGeneration, defaultTier: .lightweight)
            ?? legacyOpenAIThemeProfile()
            ?? quickProfile

        if let quickProfile {
            routeAssignments.append(
                ProviderRouteAssignmentRecord(route: .quick, modelProfileID: quickProfile.id)
            )
        }

        if let deepProfile {
            routeAssignments.append(
                ProviderRouteAssignmentRecord(route: .deep, modelProfileID: deepProfile.id)
            )
        }

        if let themeProfile {
            routeAssignments.append(
                ProviderRouteAssignmentRecord(route: .themeGeneration, modelProfileID: themeProfile.id)
            )
        }

        return ScopeProviderRuntimeState(
            credentials: credentials,
            connections: connections,
            modelProfiles: modelProfiles,
            routeAssignments: routeAssignments
        )
    }
}

struct ScopeThemeRouter {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func isConfigured(
        credentials: [ProviderCredentialRecord],
        connections: [ProviderConnectionRecord],
        modelProfiles: [ProviderModelProfileRecord],
        routeAssignments: [ProviderRouteAssignmentRecord]
    ) -> Bool {
        (try? resolveContext(
            credentials: credentials,
            connections: connections,
            modelProfiles: modelProfiles,
            routeAssignments: routeAssignments
        )) != nil
    }

    func generateRecipe(
        for scope: ScopeRecord,
        credentials: [ProviderCredentialRecord],
        connections: [ProviderConnectionRecord],
        modelProfiles: [ProviderModelProfileRecord],
        routeAssignments: [ProviderRouteAssignmentRecord]
    ) async throws -> ScopeThemeRecipe {
        let context = try resolveContext(
            credentials: credentials,
            connections: connections,
            modelProfiles: modelProfiles,
            routeAssignments: routeAssignments
        )

        let request = ScopeThemeGenerationRequest(scope: scope)

        switch context.connection.providerKind {
        case .openAI:
            return try await OpenAIScopeThemeAdapter(session: session).generateRecipe(
                request: request,
                profile: context.profile,
                connection: context.connection,
                credentialValue: context.credentialValue
            )
        case .anthropic:
            return try await AnthropicScopeThemeAdapter(session: session).generateRecipe(
                request: request,
                profile: context.profile,
                connection: context.connection,
                credentialValue: context.credentialValue
            )
        case .gemini:
            return try await GeminiScopeThemeAdapter(session: session).generateRecipe(
                request: request,
                profile: context.profile,
                connection: context.connection,
                credentialValue: context.credentialValue
            )
        }
    }

    private func resolveContext(
        credentials: [ProviderCredentialRecord],
        connections: [ProviderConnectionRecord],
        modelProfiles: [ProviderModelProfileRecord],
        routeAssignments: [ProviderRouteAssignmentRecord]
    ) throws -> ScopeThemeResolvedContext {
        guard let routeAssignment =
            routeAssignments.first(where: { $0.route == .themeGeneration }) ??
            routeAssignments.first(where: { $0.route == .quick }) else {
            throw ScopeThemeProviderError.missingConfiguredRoute
        }

        guard let profile = modelProfiles.first(where: {
            $0.id == routeAssignment.modelProfileID &&
            $0.isEnabled &&
            $0.capabilities.contains(.structuredOutputs)
        }) else {
            throw ScopeThemeProviderError.missingConfiguredRoute
        }

        guard let connection = connections.first(where: {
            $0.id == profile.connectionID && $0.isEnabled
        }) else {
            throw ScopeThemeProviderError.missingConfiguredRoute
        }

        guard let credential = credentials.first(where: { $0.id == connection.credentialID }) else {
            throw ScopeThemeProviderError.missingCredential(
                "Missing credential reference for \(connection.displayName)."
            )
        }

        guard let credentialValue = credentialValue(for: credential) else {
            throw ScopeThemeProviderError.missingCredential(
                "Add a \(connection.providerKind.displayName) API key before requesting generated scope looks."
            )
        }

        return ScopeThemeResolvedContext(
            profile: profile,
            connection: connection,
            credentialValue: credentialValue
        )
    }

    private func credentialValue(for credential: ProviderCredentialRecord) -> String? {
        switch credential.storageKind {
        case .environmentVariable:
            return ProcessInfo.processInfo.environment[credential.secretReference]?.trimmedNonEmpty
        case .keychain:
            return nil
        }
    }
}

private struct ScopeThemeResolvedContext {
    let profile: ProviderModelProfileRecord
    let connection: ProviderConnectionRecord
    let credentialValue: String
}

private protocol ScopeThemeAdapter {
    func generateRecipe(
        request: ScopeThemeGenerationRequest,
        profile: ProviderModelProfileRecord,
        connection: ProviderConnectionRecord,
        credentialValue: String
    ) async throws -> ScopeThemeRecipe
}

private struct OpenAIScopeThemeAdapter: ScopeThemeAdapter {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func generateRecipe(
        request: ScopeThemeGenerationRequest,
        profile: ProviderModelProfileRecord,
        connection: ProviderConnectionRecord,
        credentialValue: String
    ) async throws -> ScopeThemeRecipe {
        var urlRequest = URLRequest(url: try endpoint(for: connection))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(credentialValue)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try requestBody(for: request, modelID: profile.modelID)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScopeThemeProviderError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data) {
                throw ScopeThemeProviderError.requestFailed(apiError.error.message)
            }

            throw ScopeThemeProviderError.requestFailed(
                "Theme request failed with status \(httpResponse.statusCode)."
            )
        }

        let envelope = try JSONDecoder().decode(OpenAIResponseEnvelope.self, from: data)
        if let refusal = envelope.refusalText {
            throw ScopeThemeProviderError.requestFailed(refusal)
        }

        guard let outputText = envelope.outputText else {
            throw ScopeThemeProviderError.missingStructuredOutput
        }

        let payload = try JSONDecoder().decode(ScopeThemeRecipePayload.self, from: Data(outputText.utf8))
        return try payload.validated(modelID: profile.modelID, providerKind: .openAI)
    }

    private func endpoint(for connection: ProviderConnectionRecord) throws -> URL {
        let baseURLString = connection.endpointOverride?.trimmedNonEmpty ?? "https://api.openai.com"
        guard var endpointString = baseURLString.trimmedNonEmpty else {
            throw ScopeThemeProviderError.invalidBaseURL(baseURLString)
        }

        if endpointString.hasSuffix("/") {
            endpointString.removeLast()
        }

        if endpointString.hasSuffix("/v1/responses") {
            guard let url = URL(string: endpointString) else {
                throw ScopeThemeProviderError.invalidBaseURL(endpointString)
            }
            return url
        }

        if endpointString.hasSuffix("/v1") {
            endpointString += "/responses"
        } else {
            endpointString += "/v1/responses"
        }

        guard let url = URL(string: endpointString) else {
            throw ScopeThemeProviderError.invalidBaseURL(endpointString)
        }
        return url
    }

    private func requestBody(for request: ScopeThemeGenerationRequest, modelID: String) throws -> Data {
        let body: [String: Any] = [
            "model": modelID,
            "store": false,
            "instructions": request.instructions,
            "input": [
                [
                    "role": "user",
                    "content": request.prompt,
                ],
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "scope_theme_recipe",
                    "strict": true,
                    "schema": ScopeThemeSchema.jsonObject,
                ],
            ],
        ]

        return try JSONSerialization.data(withJSONObject: body)
    }
}

private struct AnthropicScopeThemeAdapter: ScopeThemeAdapter {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func generateRecipe(
        request: ScopeThemeGenerationRequest,
        profile: ProviderModelProfileRecord,
        connection: ProviderConnectionRecord,
        credentialValue: String
    ) async throws -> ScopeThemeRecipe {
        var urlRequest = URLRequest(url: try endpoint(for: connection))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(credentialValue, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try requestBody(for: request, modelID: profile.modelID)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScopeThemeProviderError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(AnthropicErrorEnvelope.self, from: data) {
                throw ScopeThemeProviderError.requestFailed(apiError.error.message)
            }

            throw ScopeThemeProviderError.requestFailed(
                "Theme request failed with status \(httpResponse.statusCode)."
            )
        }

        let envelope = try JSONDecoder().decode(AnthropicMessageResponse.self, from: data)
        if envelope.stopReason == "refusal" {
            throw ScopeThemeProviderError.requestFailed(
                envelope.primaryText ?? "The provider refused to generate a scope theme."
            )
        }

        guard let payload = envelope.toolPayload(named: "record_scope_theme") else {
            throw ScopeThemeProviderError.missingStructuredOutput
        }

        return try payload.validated(modelID: profile.modelID, providerKind: .anthropic)
    }

    private func endpoint(for connection: ProviderConnectionRecord) throws -> URL {
        let baseURLString = connection.endpointOverride?.trimmedNonEmpty ?? "https://api.anthropic.com"
        guard var endpointString = baseURLString.trimmedNonEmpty else {
            throw ScopeThemeProviderError.invalidBaseURL(baseURLString)
        }

        if endpointString.hasSuffix("/") {
            endpointString.removeLast()
        }

        if endpointString.hasSuffix("/v1/messages") {
            guard let url = URL(string: endpointString) else {
                throw ScopeThemeProviderError.invalidBaseURL(endpointString)
            }
            return url
        }

        if endpointString.hasSuffix("/v1") {
            endpointString += "/messages"
        } else {
            endpointString += "/v1/messages"
        }

        guard let url = URL(string: endpointString) else {
            throw ScopeThemeProviderError.invalidBaseURL(endpointString)
        }
        return url
    }

    private func requestBody(for request: ScopeThemeGenerationRequest, modelID: String) throws -> Data {
        let body: [String: Any] = [
            "model": modelID,
            "max_tokens": 512,
            "system": request.instructions,
            "messages": [
                [
                    "role": "user",
                    "content": request.prompt,
                ],
            ],
            "tools": [
                [
                    "name": "record_scope_theme",
                    "description": "Return the scope theme recipe as one structured tool call that exactly matches the schema.",
                    "input_schema": ScopeThemeSchema.jsonObject,
                    "strict": true,
                ],
            ],
            "tool_choice": [
                "type": "tool",
                "name": "record_scope_theme",
            ],
        ]

        return try JSONSerialization.data(withJSONObject: body)
    }
}

private struct GeminiScopeThemeAdapter: ScopeThemeAdapter {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func generateRecipe(
        request: ScopeThemeGenerationRequest,
        profile: ProviderModelProfileRecord,
        connection: ProviderConnectionRecord,
        credentialValue: String
    ) async throws -> ScopeThemeRecipe {
        var urlRequest = URLRequest(url: try endpoint(for: connection, modelID: profile.modelID))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(credentialValue, forHTTPHeaderField: "x-goog-api-key")
        urlRequest.httpBody = try requestBody(for: request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScopeThemeProviderError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(GeminiErrorEnvelope.self, from: data) {
                throw ScopeThemeProviderError.requestFailed(apiError.error.message)
            }

            throw ScopeThemeProviderError.requestFailed(
                "Theme request failed with status \(httpResponse.statusCode)."
            )
        }

        let envelope = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
        guard let outputText = envelope.outputText else {
            throw ScopeThemeProviderError.missingStructuredOutput
        }

        let payload = try JSONDecoder().decode(ScopeThemeRecipePayload.self, from: Data(outputText.utf8))
        return try payload.validated(modelID: profile.modelID, providerKind: .gemini)
    }

    private func endpoint(for connection: ProviderConnectionRecord, modelID: String) throws -> URL {
        let baseURLString = connection.endpointOverride?.trimmedNonEmpty ?? "https://generativelanguage.googleapis.com"
        guard var endpointString = baseURLString.trimmedNonEmpty else {
            throw ScopeThemeProviderError.invalidBaseURL(baseURLString)
        }

        if endpointString.hasSuffix("/") {
            endpointString.removeLast()
        }

        let terminalPath = "/v1beta/models/\(modelID):generateContent"
        if endpointString.hasSuffix(terminalPath) {
            guard let url = URL(string: endpointString) else {
                throw ScopeThemeProviderError.invalidBaseURL(endpointString)
            }
            return url
        }

        if endpointString.hasSuffix("/v1beta/models") {
            endpointString += "/\(modelID):generateContent"
        } else if endpointString.hasSuffix("/v1beta") {
            endpointString += "/models/\(modelID):generateContent"
        } else {
            endpointString += terminalPath
        }

        guard let url = URL(string: endpointString) else {
            throw ScopeThemeProviderError.invalidBaseURL(endpointString)
        }
        return url
    }

    private func requestBody(for request: ScopeThemeGenerationRequest) throws -> Data {
        let combinedPrompt = "\(request.instructions)\n\n\(request.prompt)"
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": combinedPrompt],
                    ],
                ],
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseJsonSchema": ScopeThemeSchema.jsonObject,
            ],
        ]

        return try JSONSerialization.data(withJSONObject: body)
    }
}

private struct ScopeThemeGenerationRequest {
    let scopeTitle: String
    let summary: String
    let categories: String
    let signals: String
    let memoryHints: String

    init(scope: ScopeRecord) {
        scopeTitle = scope.title
        summary = scope.summary
        categories = scope.categoryPreview.joined(separator: ", ")
        signals = scope.cardSignals.prefix(2).map(\.text).joined(separator: "; ")
        memoryHints = scope.recentMemory.prefix(2).map(\.title).joined(separator: "; ")
    }

    var instructions: String {
        """
        You generate scope-specific interface themes for an iPhone app called Scope.
        The product should feel calm, editorial, trustworthy, and easy to re-enter.
        Keep the result restrained and legible.
        Never produce flashy, neon, futuristic, or dashboard-like looks.
        Choose the most fitting motif, hero style, section layout, and palette for the scope.
        Return only the structured scope theme recipe.
        """
    }

    var prompt: String {
        """
        Design a stable scope look for this context.

        Scope title: \(scopeTitle)
        Summary: \(summary)
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

private enum ScopeThemeSchema {
    static var jsonObject: [String: Any] {
        [
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

    func validated(modelID: String, providerKind: ProviderKind) throws -> ScopeThemeRecipe {
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
            providerKind: providerKind,
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

private struct AnthropicMessageResponse: Decodable {
    let content: [AnthropicContentBlock]
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case content
        case stopReason = "stop_reason"
    }

    var primaryText: String? {
        let text = content.compactMap(\.text).joined(separator: "\n").trimmedNonEmpty
        return text
    }

    func toolPayload(named name: String) -> ScopeThemeRecipePayload? {
        content.first(where: { $0.type == "tool_use" && $0.name == name })?.input
    }
}

private struct AnthropicContentBlock: Decodable {
    let type: String
    let text: String?
    let name: String?
    let input: ScopeThemeRecipePayload?
}

private struct AnthropicErrorEnvelope: Decodable {
    let error: AnthropicErrorPayload
}

private struct AnthropicErrorPayload: Decodable {
    let message: String
}

private struct GeminiGenerateContentResponse: Decodable {
    let candidates: [GeminiCandidate]?

    var outputText: String? {
        let parts = candidates?
            .compactMap(\.content)
            .flatMap(\.parts)
            .compactMap(\.text)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: "\n")
    }
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent?
}

private struct GeminiContent: Decodable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Decodable {
    let text: String?
}

private struct GeminiErrorEnvelope: Decodable {
    let error: GeminiErrorPayload
}

private struct GeminiErrorPayload: Decodable {
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

private extension InferenceRouteKind {
    var environmentPrefix: String {
        switch self {
        case .quick:
            return "QUICK"
        case .deep:
            return "DEEP"
        case .themeGeneration:
            return "THEME"
        case .captureProcessing:
            return "CAPTURE"
        case .replyGeneration:
            return "REPLY"
        }
    }

    var displayName: String {
        switch self {
        case .quick:
            return "Quick"
        case .deep:
            return "Deep"
        case .themeGeneration:
            return "Theme"
        case .captureProcessing:
            return "Capture"
        case .replyGeneration:
            return "Reply"
        }
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

    var providerKindValue: ProviderKind? {
        switch lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
        case "openai", "open-ai":
            return .openAI
        case "anthropic", "claude":
            return .anthropic
        case "gemini", "google":
            return .gemini
        default:
            return nil
        }
    }
}
