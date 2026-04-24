import Foundation

enum SeedData {
    static let scopes: [ScopeRecord] = [
        ScopeRecord(
            id: UUID(uuidString: "1A79B4D6-31A5-48C2-9C4E-000000000001")!,
            title: "Founder Ideas",
            summary: "Landing page positioning is still fuzzy. Focus on audience, promise, and proof.",
            memoryMode: .relevantGlobal,
            categories: [
                ScopeCategoryRecord(name: "products", priority: .pinned),
                ScopeCategoryRecord(name: "audiences", priority: .pinned),
                ScopeCategoryRecord(name: "experiments"),
            ],
            recentMemory: [
                MemoryItemRecord(
                    scopeID: UUID(uuidString: "1A79B4D6-31A5-48C2-9C4E-000000000001")!,
                    title: "Audience is still too broad",
                    body: "Narrow the first pass to one clear reader instead of multiple personas.",
                    sourceKind: .userAuthored,
                    reviewState: .active,
                    categoryNames: ["audiences"]
                ),
                MemoryItemRecord(
                    scopeID: UUID(uuidString: "1A79B4D6-31A5-48C2-9C4E-000000000001")!,
                    title: "Need clearer proof",
                    body: "The landing page needs a more concrete proof point near the top.",
                    sourceKind: .extracted,
                    reviewState: .active,
                    categoryNames: ["products", "experiments"]
                ),
            ],
            cardSignals: [
                ScopeCardSignalRecord(
                    kind: .waitingOnUser,
                    text: "choose primary audience"
                ),
                ScopeCardSignalRecord(
                    kind: .backgroundUpdate,
                    text: "1 new research briefing"
                ),
            ],
            lastOpenedAt: .now.addingTimeInterval(-3600),
            preferPinnedCategories: true,
            userAuthoredFirst: true,
            allowRelevantGlobal: true
        ),
        ScopeRecord(
            id: UUID(uuidString: "1A79B4D6-31A5-48C2-9C4E-000000000002")!,
            title: "Japan Trip",
            summary: "Kyoto stay, train plan, and the food shortlist still need tightening.",
            memoryMode: .scopeOnly,
            categories: [
                ScopeCategoryRecord(name: "dates", priority: .pinned),
                ScopeCategoryRecord(name: "lodging", priority: .pinned),
                ScopeCategoryRecord(name: "restaurants"),
            ],
            recentMemory: [
                MemoryItemRecord(
                    scopeID: UUID(uuidString: "1A79B4D6-31A5-48C2-9C4E-000000000002")!,
                    title: "Kyoto hotel check-in",
                    body: "Check-in starts on May 12 after 3 PM.",
                    sourceKind: .userAuthored,
                    reviewState: .active,
                    categoryNames: ["lodging", "dates"]
                ),
            ],
            cardSignals: [
                ScopeCardSignalRecord(
                    kind: .waitingOnUser,
                    text: "confirm Kyoto hotel"
                ),
            ],
            lastOpenedAt: .now.addingTimeInterval(-86_400),
            preferPinnedCategories: true,
            userAuthoredFirst: true,
            allowRelevantGlobal: false
        ),
        ScopeRecord(
            id: UUID(uuidString: "1A79B4D6-31A5-48C2-9C4E-000000000003")!,
            title: "Strength Training",
            summary: "Deload week and shoulder notes are the main focus.",
            memoryMode: .manualOnly,
            categories: [
                ScopeCategoryRecord(name: "goals", priority: .pinned),
                ScopeCategoryRecord(name: "injuries"),
                ScopeCategoryRecord(name: "routines"),
            ],
            recentMemory: [
                MemoryItemRecord(
                    scopeID: UUID(uuidString: "1A79B4D6-31A5-48C2-9C4E-000000000003")!,
                    title: "Shoulder note",
                    body: "Keep overhead work light during the current deload week.",
                    sourceKind: .userAuthored,
                    reviewState: .active,
                    categoryNames: ["injuries", "routines"]
                ),
            ],
            cardSignals: [
                ScopeCardSignalRecord(
                    kind: .backgroundUpdate,
                    text: "1 new programming note"
                ),
            ],
            lastOpenedAt: .now.addingTimeInterval(-259_200),
            preferPinnedCategories: true,
            userAuthoredFirst: true,
            allowRelevantGlobal: false
        ),
    ]
}
