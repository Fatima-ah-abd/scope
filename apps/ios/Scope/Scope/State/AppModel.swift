import Foundation
import Observation

@Observable
@MainActor
final class AppModel {
    private struct AutoScopeCandidate {
        let scopeID: UUID
        let score: Int
    }

    private struct WaitingSignalCandidate {
        let signal: ScopeCardSignalRecord
        let overlapCount: Int
        let waitingTokenCount: Int

        var coverage: Double {
            guard waitingTokenCount > 0 else { return 0 }
            return Double(overlapCount) / Double(waitingTokenCount)
        }
    }

    private struct WaitingSignalDecision {
        let signal: ScopeCardSignalRecord
        let confidenceBand: AutomationConfidenceBand
        let applicationState: AutomationApplicationState
        let reason: String
    }

    @ObservationIgnored private let scopeThemeProvider = ScopeThemeRouter()
    @ObservationIgnored private var themeGenerationInFlight: Set<UUID> = []
    @ObservationIgnored private var themeGenerationRequestIDs: [UUID: UUID] = [:]

    var scopes: [ScopeRecord]
    var sourceAssets: [SourceAssetRecord]
    var providerCredentials: [ProviderCredentialRecord]
    var providerConnections: [ProviderConnectionRecord]
    var providerModelProfiles: [ProviderModelProfileRecord]
    var providerRouteAssignments: [ProviderRouteAssignmentRecord]
    var homeOwnerName = ""
    var showScopeCardTimestamps = false
    var automationNotice: AutomationNoticeRecord?

    init(
        scopes: [ScopeRecord] = SeedData.scopes,
        sourceAssets: [SourceAssetRecord] = [],
        providerRuntime: ScopeProviderRuntimeState = .current
    ) {
        self.scopes = scopes
        self.sourceAssets = sourceAssets
        self.providerCredentials = providerRuntime.credentials
        self.providerConnections = providerRuntime.connections
        self.providerModelProfiles = providerRuntime.modelProfiles
        self.providerRouteAssignments = providerRuntime.routeAssignments
    }

    var activeScopes: [ScopeRecord] {
        scopes.sorted { lhs, rhs in
            let leftDate = lhs.lastOpenedAt ?? .distantPast
            let rightDate = rhs.lastOpenedAt ?? .distantPast
            if leftDate != rightDate {
                return leftDate > rightDate
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    var homeTitle: String {
        let cleanedName = homeOwnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedName.isEmpty {
            return "Your scopes"
        }

        return "\(cleanedName)'s scopes"
    }

    func scope(for scopeID: UUID) -> ScopeRecord? {
        scopes.first(where: { $0.id == scopeID })
    }

    var isScopeThemeProviderConfigured: Bool {
        scopeThemeProvider.isConfigured(
            credentials: providerCredentials,
            connections: providerConnections,
            modelProfiles: providerModelProfiles,
            routeAssignments: providerRouteAssignments
        )
    }

    func setHomeOwnerName(_ name: String) {
        homeOwnerName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func markScopeOpened(_ scopeID: UUID) {
        guard let index = indexOfScope(scopeID) else { return }
        scopes[index].lastOpenedAt = .now
    }

    func prepareScopeDetail(_ scopeID: UUID) async {
        markScopeOpened(scopeID)
        await ensureThemeRecipe(for: scopeID)
    }

    func primeThemeRecipes(for scopeIDs: [UUID]) async {
        var seenScopeIDs: Set<UUID> = []

        for scopeID in scopeIDs where seenScopeIDs.insert(scopeID).inserted {
            await ensureThemeRecipe(for: scopeID)
        }
    }

    func ensureThemeRecipe(for scopeID: UUID) async {
        await fetchThemeRecipe(for: scopeID, forceRefresh: false)
    }

    func regenerateThemeRecipe(for scopeID: UUID) async {
        await fetchThemeRecipe(for: scopeID, forceRefresh: true)
    }

    func useDefaultTheme(for scopeID: UUID) {
        guard let index = indexOfScope(scopeID) else { return }
        if themeGenerationInFlight.contains(scopeID) {
            themeGenerationRequestIDs[scopeID] = UUID()
        } else {
            themeGenerationRequestIDs[scopeID] = nil
        }
        scopes[index].themeRecipe = nil
    }

    func dismissAutomationNotice() {
        automationNotice = nil
    }

    @discardableResult
    func createScope(title: String, note: String) -> ScopeRecord {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let categories = suggestedCategories(for: cleanedTitle, note: note)
            .map { ScopeCategoryRecord(name: $0) }

        let scope = ScopeRecord(
            title: cleanedTitle,
            summary: note.isEmpty ? "Start with a note, photo, or voice memo." : note,
            memoryMode: .scopeOnly,
            categories: categories,
            recentMemory: [],
            cardSignals: [],
            lastOpenedAt: .now,
            allowRelevantGlobal: false
        )

        scopes.insert(scope, at: 0)
        return scope
    }

    func suggestedDestination(
        preferredScopeID: UUID?,
        noteText: String = "",
        includesPhoto: Bool = false,
        includesVideo: Bool = false
    ) -> CaptureScopeSuggestion {
        if let preferredScopeID, scope(for: preferredScopeID) != nil {
            return CaptureScopeSuggestion(
                scopeID: preferredScopeID,
                assignmentSource: .inScope,
                reason: "Started inside this scope",
                confidenceBand: .high,
                applicationState: .silentApply
            )
        }

        guard let fallbackScopeID = activeScopes.first?.id else {
            return CaptureScopeSuggestion(
                scopeID: nil,
                assignmentSource: .autoSuggested,
                reason: "Create a scope first",
                confidenceBand: .low,
                applicationState: .requiresManualReview
            )
        }

        let cleanedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let contentTokens = searchableTokens(from: cleanedNote)

        if contentTokens.isEmpty {
            return CaptureScopeSuggestion(
                scopeID: fallbackScopeID,
                assignmentSource: .autoSuggested,
                reason: "Based on recent scope activity",
                confidenceBand: .medium,
                applicationState: .notifiedApply
            )
        }

        let candidates = activeScopes
            .map {
                AutoScopeCandidate(
                    scopeID: $0.id,
                    score: autoScopeScore(
                        for: $0,
                        tokens: contentTokens,
                        includesPhoto: includesPhoto,
                        includesVideo: includesVideo
                    )
                )
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                return lhs.scopeID.uuidString < rhs.scopeID.uuidString
            }

        guard let bestCandidate = candidates.first else {
            return CaptureScopeSuggestion(
                scopeID: nil,
                assignmentSource: .autoSuggested,
                reason: "Choose a scope",
                confidenceBand: .low,
                applicationState: .requiresManualReview
            )
        }

        let secondBestScore = candidates.dropFirst().first?.score ?? 0
        let scoreGap = bestCandidate.score - secondBestScore

        if bestCandidate.score >= 16 && scoreGap >= 6 {
            return CaptureScopeSuggestion(
                scopeID: bestCandidate.scopeID,
                assignmentSource: .autoAssigned,
                reason: "Strong match from this capture",
                confidenceBand: .high,
                applicationState: .silentApply
            )
        }

        if bestCandidate.score >= 7 && scoreGap >= 2 {
            return CaptureScopeSuggestion(
                scopeID: bestCandidate.scopeID,
                assignmentSource: .autoAssigned,
                reason: "Likely scope from this capture",
                confidenceBand: .medium,
                applicationState: .notifiedApply
            )
        }

        return CaptureScopeSuggestion(
            scopeID: bestCandidate.scopeID,
            assignmentSource: .autoSuggested,
            reason: "Needs confirmation",
            confidenceBand: .low,
            applicationState: .requiresManualReview
        )
    }

    func availableScopeChoices() -> [ScopeRecord] {
        activeScopes
    }

    func waitingSignals(for scopeID: UUID) -> [ScopeCardSignalRecord] {
        scope(for: scopeID)?.cardSignals.filter { $0.kind == .waitingOnUser } ?? []
    }

    func toggleCategoryPin(scopeID: UUID, categoryID: UUID) {
        guard let scopeIndex = indexOfScope(scopeID),
              let categoryIndex = scopes[scopeIndex].categories.firstIndex(where: { $0.id == categoryID }) else {
            return
        }

        scopes[scopeIndex].categories[categoryIndex].priority =
            scopes[scopeIndex].categories[categoryIndex].priority == .pinned ? .normal : .pinned
    }

    func renameCategory(scopeID: UUID, categoryID: UUID, name: String) {
        guard let scopeIndex = indexOfScope(scopeID),
              let categoryIndex = scopes[scopeIndex].categories.firstIndex(where: { $0.id == categoryID }) else {
            return
        }

        scopes[scopeIndex].categories[categoryIndex].name = name
    }

    func setCategoryRetrieval(scopeID: UUID, categoryID: UUID, enabled: Bool) {
        guard let scopeIndex = indexOfScope(scopeID),
              let categoryIndex = scopes[scopeIndex].categories.firstIndex(where: { $0.id == categoryID }) else {
            return
        }

        scopes[scopeIndex].categories[categoryIndex].retrievalEnabled = enabled
    }

    func setPreferPinnedCategories(scopeID: UUID, enabled: Bool) {
        guard let index = indexOfScope(scopeID) else { return }
        scopes[index].preferPinnedCategories = enabled
    }

    func setUserAuthoredFirst(scopeID: UUID, enabled: Bool) {
        guard let index = indexOfScope(scopeID) else { return }
        scopes[index].userAuthoredFirst = enabled
    }

    func setAllowRelevantGlobal(scopeID: UUID, enabled: Bool) {
        guard let index = indexOfScope(scopeID) else { return }
        scopes[index].allowRelevantGlobal = enabled
        scopes[index].memoryMode = enabled ? .relevantGlobal : .scopeOnly
    }

    func saveQuickRecording(
        duration: TimeInterval,
        scopeID: UUID?,
        assignmentSource: ScopeAssignmentSource,
        suggestion: CaptureScopeSuggestion?
    ) -> CapturePersistResult {
        guard let resolution = resolveCaptureDestination(
            explicitScopeID: scopeID,
            assignmentSource: assignmentSource,
            noteText: "",
            includesPhoto: false,
            includesVideo: false
        ) else {
            return .requiresManualScope
        }

        let title = "Voice memo"
        let durationLabel = ScopeFormatters.duration.string(from: duration) ?? "0:00"

        let asset = SourceAssetRecord(
            scopeID: resolution.scopeID,
            kind: .audio,
            captureIntent: .quickRecord,
            scopeAssignmentSource: resolution.assignmentSource,
            displayTitle: "\(title) • \(durationLabel)",
            durationSeconds: duration
        )

        let assetID = asset.id
        sourceAssets.insert(asset, at: 0)

        let memory = MemoryItemRecord(
            scopeID: resolution.scopeID,
            title: title,
            body: "Recorded a \(durationLabel) voice note.",
            sourceKind: .userAuthored,
            reviewState: .active,
            categoryNames: captureCategories(for: resolution.scopeID)
        )

        let memoryID = memory.id
        append(memory: memory, to: resolution.scopeID)
        let didQueueWaitingNotice = handleWaitingSignalDecision(scopeID: resolution.scopeID, noteText: memory.body)
        if !didQueueWaitingNotice {
            queueAutomationNoticeIfNeeded(
                suggestion: suggestion,
                resolvedScopeID: resolution.scopeID,
                captureReference: CaptureReference(memoryID: memoryID, assetIDs: [assetID])
            )
        }
        return .saved(scopeID: resolution.scopeID)
    }

    func saveCapture(
        kind: SourceAssetKind,
        scopeID: UUID?,
        assignmentSource: ScopeAssignmentSource,
        noteText: String,
        suggestion: CaptureScopeSuggestion?
    ) -> CapturePersistResult {
        guard let resolution = resolveCaptureDestination(
            explicitScopeID: scopeID,
            assignmentSource: assignmentSource,
            noteText: noteText,
            includesPhoto: kind == .photo,
            includesVideo: kind == .video
        ) else {
            return .requiresManualScope
        }

        let title = switch kind {
        case .note: "Quick note"
        case .photo: "Saved photo"
        case .video: "Saved video"
        case .link: "Saved link"
        case .audio: "Voice memo"
        }

        let body: String = {
            let cleaned = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                return cleaned
            }

            return switch kind {
            case .note: "Saved a quick note."
            case .photo: "Saved a photo placeholder."
            case .video: "Saved a video placeholder."
            case .link: "Saved a link placeholder."
            case .audio: "Recorded a voice note."
            }
        }()

        let asset = SourceAssetRecord(
            scopeID: resolution.scopeID,
            kind: kind,
            captureIntent: kind == .note ? .quickNote : .genericAdd,
            scopeAssignmentSource: resolution.assignmentSource,
            displayTitle: title,
            durationSeconds: nil
        )

        let assetID = asset.id
        sourceAssets.insert(asset, at: 0)

        let memory = MemoryItemRecord(
            scopeID: resolution.scopeID,
            title: title,
            body: body,
            sourceKind: .userAuthored,
            reviewState: .active,
            categoryNames: captureCategories(for: resolution.scopeID)
        )

        let memoryID = memory.id
        append(memory: memory, to: resolution.scopeID)
        let didQueueWaitingNotice = handleWaitingSignalDecision(scopeID: resolution.scopeID, noteText: body)
        if !didQueueWaitingNotice {
            queueAutomationNoticeIfNeeded(
                suggestion: suggestion,
                resolvedScopeID: resolution.scopeID,
                captureReference: CaptureReference(memoryID: memoryID, assetIDs: [assetID])
            )
        }
        return .saved(scopeID: resolution.scopeID)
    }

    func saveCaptureBundle(
        scopeID: UUID?,
        assignmentSource: ScopeAssignmentSource,
        noteText: String,
        includesPhoto: Bool,
        includesVideo: Bool,
        suggestion: CaptureScopeSuggestion?
    ) -> CapturePersistResult {
        guard let resolution = resolveCaptureDestination(
            explicitScopeID: scopeID,
            assignmentSource: assignmentSource,
            noteText: noteText,
            includesPhoto: includesPhoto,
            includesVideo: includesVideo
        ) else {
            return .requiresManualScope
        }

        let cleanedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        var createdAssetIDs: [UUID] = []

        if !cleanedNote.isEmpty {
            let noteAsset = SourceAssetRecord(
                scopeID: resolution.scopeID,
                kind: .note,
                captureIntent: .quickNote,
                scopeAssignmentSource: resolution.assignmentSource,
                displayTitle: "Quick note",
                durationSeconds: nil
            )
            createdAssetIDs.append(noteAsset.id)
            sourceAssets.insert(noteAsset, at: 0)
        }

        if includesPhoto {
            let photoAsset = SourceAssetRecord(
                scopeID: resolution.scopeID,
                kind: .photo,
                captureIntent: .genericAdd,
                scopeAssignmentSource: resolution.assignmentSource,
                displayTitle: "Saved photo",
                durationSeconds: nil
            )
            createdAssetIDs.append(photoAsset.id)
            sourceAssets.insert(photoAsset, at: 0)
        }

        if includesVideo {
            let videoAsset = SourceAssetRecord(
                scopeID: resolution.scopeID,
                kind: .video,
                captureIntent: .genericAdd,
                scopeAssignmentSource: resolution.assignmentSource,
                displayTitle: "Saved video",
                durationSeconds: nil
            )
            createdAssetIDs.append(videoAsset.id)
            sourceAssets.insert(videoAsset, at: 0)
        }

        let title: String
        let body: String

        if !cleanedNote.isEmpty {
            title = includesPhoto || includesVideo ? "Capture note" : "Quick note"
            body = cleanedNote
        } else if includesPhoto && includesVideo {
            title = "Saved image and video"
            body = "Added an image and a video to this scope."
        } else if includesPhoto {
            title = "Saved image"
            body = "Added an image to this scope."
        } else if includesVideo {
            title = "Saved video"
            body = "Added a video to this scope."
        } else {
            queueAutomationNoticeIfNeeded(
                suggestion: suggestion,
                resolvedScopeID: resolution.scopeID,
                captureReference: CaptureReference(memoryID: nil, assetIDs: createdAssetIDs)
            )
            return .saved(scopeID: resolution.scopeID)
        }

        let memory = MemoryItemRecord(
            scopeID: resolution.scopeID,
            title: title,
            body: body,
            sourceKind: .userAuthored,
            reviewState: .active,
            categoryNames: captureCategories(for: resolution.scopeID)
        )

        let memoryID = memory.id
        append(memory: memory, to: resolution.scopeID)
        let didQueueWaitingNotice = handleWaitingSignalDecision(scopeID: resolution.scopeID, noteText: body)
        if !didQueueWaitingNotice {
            queueAutomationNoticeIfNeeded(
                suggestion: suggestion,
                resolvedScopeID: resolution.scopeID,
                captureReference: CaptureReference(memoryID: memoryID, assetIDs: createdAssetIDs)
            )
        }
        return .saved(scopeID: resolution.scopeID)
    }

    func toggleMemoryExclusion(scopeID: UUID, memoryID: UUID) {
        guard let scopeIndex = indexOfScope(scopeID),
              let memoryIndex = scopes[scopeIndex].recentMemory.firstIndex(where: { $0.id == memoryID }) else {
            return
        }

        scopes[scopeIndex].recentMemory[memoryIndex].reviewState =
            scopes[scopeIndex].recentMemory[memoryIndex].reviewState == .excluded ? .active : .excluded
    }

    func reassignCapture(_ reference: CaptureReference, to destinationScopeID: UUID) {
        var previousScopeID: UUID?

        if let memoryID = reference.memoryID {
            for scopeIndex in scopes.indices {
                if let memoryIndex = scopes[scopeIndex].recentMemory.firstIndex(where: { $0.id == memoryID }) {
                    var memory = scopes[scopeIndex].recentMemory.remove(at: memoryIndex)
                    previousScopeID = memory.scopeID
                    memory.scopeID = destinationScopeID
                    if let destinationIndex = indexOfScope(destinationScopeID) {
                        scopes[destinationIndex].recentMemory.insert(memory, at: 0)
                    }
                    break
                }
            }
        }

        for assetID in reference.assetIDs {
            guard let assetIndex = sourceAssets.firstIndex(where: { $0.id == assetID }) else { continue }
            if previousScopeID == nil {
                previousScopeID = sourceAssets[assetIndex].scopeID
            }
            sourceAssets[assetIndex].scopeID = destinationScopeID
        }

        guard previousScopeID != destinationScopeID,
              let destinationIndex = indexOfScope(destinationScopeID) else {
            dismissAutomationNotice()
            return
        }

        scopes[destinationIndex].lastOpenedAt = .now
        dismissAutomationNotice()
    }

    func resolveWaitingSignal(signalID: UUID, in scopeID: UUID) {
        guard let scopeIndex = indexOfScope(scopeID),
              let signalIndex = scopes[scopeIndex].cardSignals.firstIndex(where: { $0.id == signalID }) else {
            dismissAutomationNotice()
            return
        }

        scopes[scopeIndex].cardSignals.remove(at: signalIndex)
        dismissAutomationNotice()
    }

    func restoreWaitingSignal(_ reference: ScopeSignalReference) {
        guard let scopeIndex = indexOfScope(reference.scopeID) else {
            dismissAutomationNotice()
            return
        }

        if scopes[scopeIndex].cardSignals.contains(where: { $0.id == reference.signal.id }) {
            dismissAutomationNotice()
            return
        }

        scopes[scopeIndex].cardSignals.insert(reference.signal, at: 0)
        dismissAutomationNotice()
    }

    private func append(memory: MemoryItemRecord, to scopeID: UUID) {
        guard let index = indexOfScope(scopeID) else { return }
        scopes[index].recentMemory.insert(memory, at: 0)
        scopes[index].lastOpenedAt = .now
    }

    private func queueAutomationNoticeIfNeeded(
        suggestion: CaptureScopeSuggestion?,
        resolvedScopeID: UUID,
        captureReference: CaptureReference
    ) {
        guard let suggestion,
              suggestion.showsHeadsUp,
              let scope = scope(for: resolvedScopeID) else {
            automationNotice = nil
            return
        }

        let canReassign = activeScopes.count > 1

        automationNotice = AutomationNoticeRecord(
            title: "Scoped to \(scope.title)",
            body: suggestion.reason,
            scopeID: resolvedScopeID,
            primaryActionTitle: canReassign ? "Change" : nil,
            secondaryActionTitle: "Dismiss",
            action: canReassign ? .reassignCapture(captureReference) : nil
        )
    }

    @discardableResult
    private func handleWaitingSignalDecision(
        scopeID: UUID,
        noteText: String
    ) -> Bool {
        guard let decision = waitingSignalDecision(scopeID: scopeID, noteText: noteText) else {
            return false
        }

        let signalReference = ScopeSignalReference(scopeID: scopeID, signal: decision.signal)

        switch decision.applicationState {
        case .silentApply:
            removeWaitingSignal(signalID: decision.signal.id, from: scopeID)
            return false
        case .notifiedApply:
            removeWaitingSignal(signalID: decision.signal.id, from: scopeID)
            automationNotice = AutomationNoticeRecord(
                title: decision.signal.text,
                body: decision.reason,
                scopeID: scopeID,
                primaryActionTitle: "Undo",
                secondaryActionTitle: "Dismiss",
                action: .restoreWaitingSignal(signalReference)
            )
            return true
        case .requiresManualReview:
            automationNotice = AutomationNoticeRecord(
                title: decision.signal.text,
                body: decision.reason,
                scopeID: scopeID,
                primaryActionTitle: "Review",
                secondaryActionTitle: "Dismiss",
                action: .reviewWaitingSignal(
                    WaitingSignalReviewReference(
                        scopeID: scopeID,
                        suggestedSignalID: decision.signal.id
                    )
                )
            )
            return true
        }
    }

    private func captureCategories(for scopeID: UUID) -> [String] {
        guard let scope = scope(for: scopeID) else { return ["general"] }

        let prioritized = scope.categories
            .filter(\.retrievalEnabled)
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority {
                    return lhs.priority == .pinned
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }

        return Array(prioritized.prefix(2).map(\.name))
    }

    private func resolveCaptureDestination(
        explicitScopeID: UUID?,
        assignmentSource: ScopeAssignmentSource,
        noteText: String,
        includesPhoto: Bool,
        includesVideo: Bool
    ) -> (scopeID: UUID, assignmentSource: ScopeAssignmentSource)? {
        if let explicitScopeID, scope(for: explicitScopeID) != nil {
            return (explicitScopeID, assignmentSource)
        }

        let suggestion = suggestedDestination(
            preferredScopeID: nil,
            noteText: noteText,
            includesPhoto: includesPhoto,
            includesVideo: includesVideo
        )

        guard !suggestion.requiresManualReview,
              let resolvedScopeID = suggestion.scopeID else {
            return nil
        }

        let resolvedAssignmentSource: ScopeAssignmentSource
        switch assignmentSource {
        case .autoSuggested, .autoAssigned:
            resolvedAssignmentSource = .autoAssigned
        case .inScope, .userSelected:
            resolvedAssignmentSource = assignmentSource
        }

        return (resolvedScopeID, resolvedAssignmentSource)
    }

    private func autoScopeScore(
        for scope: ScopeRecord,
        tokens: Set<String>,
        includesPhoto: Bool,
        includesVideo: Bool
    ) -> Int {
        let waitingText = scope.cardSignals
            .filter { $0.kind == .waitingOnUser }
            .map(\.text)
            .joined(separator: " ")
        let categoriesText = scope.categories.map(\.name).joined(separator: " ")
        let memoryText = scope.recentMemory
            .prefix(3)
            .map { "\($0.title) \($0.body)" }
            .joined(separator: " ")

        var score = 0
        score += tokenMatchScore(tokens, in: scope.title, weight: 8)
        score += tokenMatchScore(tokens, in: categoriesText, weight: 6)
        score += tokenMatchScore(tokens, in: waitingText, weight: 7)
        score += tokenMatchScore(tokens, in: scope.summary, weight: 4)
        score += tokenMatchScore(tokens, in: memoryText, weight: 3)

        if includesPhoto || includesVideo {
            score += tokenMatchScore(tokens, in: waitingText, weight: 1)
        }

        return score
    }

    private func waitingSignalDecision(scopeID: UUID, noteText: String) -> WaitingSignalDecision? {
        let captureTokens = searchableTokens(from: noteText)
        guard !captureTokens.isEmpty, let scopeIndex = indexOfScope(scopeID) else { return nil }

        let candidates = scopes[scopeIndex].cardSignals
            .filter { $0.kind == .waitingOnUser }
            .compactMap { signal -> WaitingSignalCandidate? in
                let waitingTokens = searchableTokens(from: signal.text)
                guard !waitingTokens.isEmpty else { return nil }

                let overlapCount = waitingTokens.intersection(captureTokens).count
                guard overlapCount > 0 else { return nil }

                return WaitingSignalCandidate(
                    signal: signal,
                    overlapCount: overlapCount,
                    waitingTokenCount: waitingTokens.count
                )
            }
            .sorted { lhs, rhs in
                if lhs.overlapCount != rhs.overlapCount {
                    return lhs.overlapCount > rhs.overlapCount
                }
                if lhs.coverage != rhs.coverage {
                    return lhs.coverage > rhs.coverage
                }
                return lhs.signal.text.localizedCaseInsensitiveCompare(rhs.signal.text) == .orderedAscending
            }

        guard let bestCandidate = candidates.first else {
            return nil
        }

        let secondBestOverlap = candidates.dropFirst().first?.overlapCount ?? 0
        let overlapGap = bestCandidate.overlapCount - secondBestOverlap

        if bestCandidate.coverage == 1.0, bestCandidate.waitingTokenCount >= 2 {
            return WaitingSignalDecision(
                signal: bestCandidate.signal,
                confidenceBand: .high,
                applicationState: .silentApply,
                reason: "Resolved from this capture"
            )
        }

        if bestCandidate.coverage >= 0.67,
           bestCandidate.overlapCount >= 2,
           overlapGap >= 1 {
            return WaitingSignalDecision(
                signal: bestCandidate.signal,
                confidenceBand: .medium,
                applicationState: .notifiedApply,
                reason: "Marked resolved from this capture"
            )
        }

        return WaitingSignalDecision(
            signal: bestCandidate.signal,
            confidenceBand: .low,
            applicationState: .requiresManualReview,
            reason: "Review before resolving"
        )
    }

    private func removeWaitingSignal(signalID: UUID, from scopeID: UUID) {
        guard let scopeIndex = indexOfScope(scopeID),
              let signalIndex = scopes[scopeIndex].cardSignals.firstIndex(where: { $0.id == signalID }) else {
            return
        }

        scopes[scopeIndex].cardSignals.remove(at: signalIndex)
    }

    private func tokenMatchScore(_ tokens: Set<String>, in text: String, weight: Int) -> Int {
        let haystack = text.lowercased()
        return tokens.reduce(into: 0) { partial, token in
            if haystack.contains(token) {
                partial += weight
            }
        }
    }

    private func searchableTokens(from text: String) -> Set<String> {
        let lowered = text.lowercased()
        let separators = CharacterSet.alphanumerics.inverted
        let stopWords: Set<String> = [
            "a", "an", "and", "are", "at", "be", "for", "from", "how", "i", "if", "in",
            "is", "it", "me", "my", "of", "on", "or", "so", "still", "that", "the", "this",
            "to", "up", "we", "with"
        ]

        return Set(
            lowered
                .components(separatedBy: separators)
                .filter { $0.count > 2 && !stopWords.contains($0) }
        )
    }

    // Theme generation is best-effort: keep the deterministic default until a validated provider recipe arrives.
    private func fetchThemeRecipe(for scopeID: UUID, forceRefresh: Bool) async {
        guard let scopeIndex = indexOfScope(scopeID) else {
            return
        }

        guard isScopeThemeProviderConfigured else { return }

        if !forceRefresh, scopes[scopeIndex].themeRecipe != nil {
            return
        }

        guard themeGenerationInFlight.insert(scopeID).inserted else {
            return
        }

        let requestID = UUID()
        let scopeSnapshot = scopes[scopeIndex]
        themeGenerationRequestIDs[scopeID] = requestID

        defer {
            themeGenerationInFlight.remove(scopeID)
            if themeGenerationRequestIDs[scopeID] == requestID {
                themeGenerationRequestIDs[scopeID] = nil
            }
        }

        do {
            let recipe = try await scopeThemeProvider.generateRecipe(
                for: scopeSnapshot,
                credentials: providerCredentials,
                connections: providerConnections,
                modelProfiles: providerModelProfiles,
                routeAssignments: providerRouteAssignments
            )
            guard themeGenerationRequestIDs[scopeID] == requestID else { return }
            guard let refreshedIndex = indexOfScope(scopeID) else { return }

            if !forceRefresh, scopes[refreshedIndex].themeRecipe != nil {
                return
            }

            scopes[refreshedIndex].themeRecipe = recipe
        } catch {
            return
        }
    }

    private func indexOfScope(_ scopeID: UUID) -> Int? {
        scopes.firstIndex(where: { $0.id == scopeID })
    }

    private func suggestedCategories(for title: String, note: String) -> [String] {
        let haystack = "\(title) \(note)".lowercased()

        if haystack.contains("trip") || haystack.contains("travel") || haystack.contains("japan") {
            return ["dates", "lodging", "ideas"]
        }

        if haystack.contains("train") || haystack.contains("workout") || haystack.contains("strength") {
            return ["goals", "routines", "injuries"]
        }

        if haystack.contains("idea") || haystack.contains("founder") || haystack.contains("product") {
            return ["products", "audiences", "experiments"]
        }

        if haystack.contains("photo") || haystack.contains("camera") {
            return ["gear", "locations", "techniques"]
        }

        return ["notes", "ideas", "next"]
    }
}
