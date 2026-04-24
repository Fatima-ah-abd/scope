import Foundation

enum ScopeMemoryMode: String, CaseIterable, Codable {
    case scopeOnly = "Scope only"
    case relevantGlobal = "Scope + global"
    case manualOnly = "Manual only"
    case temporary = "Temporary"
}

enum CategoryPriority: String, Codable {
    case pinned
    case normal
    case low
}

enum SourceAssetKind: String, Codable {
    case audio
    case note
    case photo
    case video
    case link
}

enum CaptureIntent: String, Codable {
    case quickRecord
    case quickNote
    case genericAdd
    case inScopeCapture
}

enum ScopeAssignmentSource: String, Codable {
    case inScope
    case userSelected
    case autoSuggested
    case autoAssigned
}

enum AutomationConfidenceBand: String, Codable {
    case high
    case medium
    case low
}

enum AutomationApplicationState: String, Codable {
    case silentApply
    case notifiedApply
    case requiresManualReview
}

enum MemorySourceKind: String, Codable {
    case userAuthored
    case extracted
    case simulated
}

enum MemoryReviewState: String, Codable {
    case suggested
    case active
    case excluded
}

enum ScopeCardSignalKind: String, Codable {
    case waitingOnUser
    case backgroundUpdate
}

struct ScopeThemeRecipe: Hashable, Codable {
    var motif: ScopeArtMotif
    var heroStyle: ScopeHeroStyle
    var sectionLayout: ScopeSectionLayout
    var headerLabel: String
    var pageCanvasHex: String
    var surfaceHex: String
    var heroFillHex: String
    var accentHex: String
    var patternHex: String
    var primaryTextHex: String
    var providerModelID: String?
    var generatedAt: Date?
}

struct CaptureScopeSuggestion: Equatable {
    let scopeID: UUID?
    let assignmentSource: ScopeAssignmentSource
    let reason: String
    let confidenceBand: AutomationConfidenceBand
    let applicationState: AutomationApplicationState

    var showsHeadsUp: Bool {
        applicationState == .notifiedApply
    }

    var requiresManualReview: Bool {
        applicationState == .requiresManualReview
    }
}

enum CapturePersistResult: Equatable {
    case saved(scopeID: UUID)
    case requiresManualScope
}

struct CaptureReference: Equatable {
    let memoryID: UUID?
    let assetIDs: [UUID]
}

struct ScopeSignalReference: Equatable {
    let scopeID: UUID
    let signal: ScopeCardSignalRecord
}

struct WaitingSignalReviewReference: Equatable {
    let scopeID: UUID
    let suggestedSignalID: UUID?
}

enum AutomationNoticeAction: Equatable {
    case reassignCapture(CaptureReference)
    case restoreWaitingSignal(ScopeSignalReference)
    case reviewWaitingSignal(WaitingSignalReviewReference)
}

enum AutomationDialogRoute: Identifiable, Equatable {
    case reassignCapture(reference: CaptureReference, currentScopeID: UUID?)
    case reviewWaitingSignal(reference: WaitingSignalReviewReference)

    var id: String {
        switch self {
        case let .reassignCapture(reference, currentScopeID):
            return "reassign-\(reference.assetIDs.map(\.uuidString).joined(separator: "-"))-\(reference.memoryID?.uuidString ?? "none")-\(currentScopeID?.uuidString ?? "none")"
        case let .reviewWaitingSignal(reference):
            return "review-waiting-\(reference.scopeID.uuidString)-\(reference.suggestedSignalID?.uuidString ?? "none")"
        }
    }
}

struct AutomationNoticeRecord: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let body: String?
    let scopeID: UUID?
    let primaryActionTitle: String?
    let secondaryActionTitle: String?
    let action: AutomationNoticeAction?
}

struct ScopeCategoryRecord: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var priority: CategoryPriority = .normal
    var retrievalEnabled = true
}

struct ScopeCardSignalRecord: Identifiable, Hashable, Codable {
    var id = UUID()
    var kind: ScopeCardSignalKind
    var text: String
}

struct MemoryItemRecord: Identifiable, Hashable, Codable {
    var id = UUID()
    var scopeID: UUID
    var title: String
    var body: String
    var sourceKind: MemorySourceKind
    var reviewState: MemoryReviewState
    var categoryNames: [String]
    var createdAt: Date = .now

    var primaryCategory: String {
        categoryNames.first ?? "general"
    }
}

struct SourceAssetRecord: Identifiable, Hashable, Codable {
    var id = UUID()
    var scopeID: UUID
    var kind: SourceAssetKind
    var captureIntent: CaptureIntent
    var scopeAssignmentSource: ScopeAssignmentSource
    var displayTitle: String
    var durationSeconds: TimeInterval?
    var createdAt: Date = .now
}

struct ScopeRecord: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var summary: String
    var memoryMode: ScopeMemoryMode
    var categories: [ScopeCategoryRecord]
    var recentMemory: [MemoryItemRecord]
    var cardSignals: [ScopeCardSignalRecord] = []
    var themeRecipe: ScopeThemeRecipe?
    var lastOpenedAt: Date?
    var preferPinnedCategories = true
    var userAuthoredFirst = true
    var allowRelevantGlobal: Bool

    var categoryPreview: [String] {
        categories.prefix(3).map(\.name)
    }
}
