import SwiftUI

struct MemoryControlsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let scopeID: UUID

    var body: some View {
        NavigationStack {
            Group {
                if let scope = appModel.scope(for: scopeID) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: ScopeTheme.spacingXLarge) {
                            VStack(alignment: .leading, spacing: ScopeTheme.spacingSmall) {
                                Text("Memory controls")
                                    .font(ScopeTheme.displayFont)
                                    .foregroundStyle(ScopeTheme.ink)

                                Text("Guide what gets saved and used here.")
                                    .font(ScopeTheme.bodyFont)
                                    .foregroundStyle(ScopeTheme.mutedInk)
                            }

                            suggestedCategories(for: scope)
                            retrievalSection(for: scope)
                        }
                        .padding(.horizontal, ScopeTheme.spacingLarge)
                        .padding(.vertical, ScopeTheme.spacingXLarge)
                    }
                    .background {
                        ScopeBackground().ignoresSafeArea()
                    }
                } else {
                    Text("This scope is unavailable.")
                        .font(ScopeTheme.bodyFont)
                        .foregroundStyle(ScopeTheme.ink)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            ScopeBackground().ignoresSafeArea()
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func suggestedCategories(for scope: ScopeRecord) -> some View {
        VStack(alignment: .leading, spacing: ScopeTheme.spacingMedium) {
            Text("Suggested categories")
                .font(ScopeTheme.sectionTitleFont)
                .foregroundStyle(ScopeTheme.ink)

            ForEach(scope.categories) { category in
                card {
                    VStack(alignment: .leading, spacing: ScopeTheme.spacingMedium) {
                        TextField(
                            "Category",
                            text: Binding(
                                get: { appModel.scope(for: scopeID)?.categories.first(where: { $0.id == category.id })?.name ?? category.name },
                                set: { appModel.renameCategory(scopeID: scopeID, categoryID: category.id, name: $0) }
                            )
                        )
                        .font(ScopeTheme.bodyFont.weight(.medium))
                        .foregroundStyle(ScopeTheme.ink)

                        HStack {
                            Button(category.priority == .pinned ? "Unpin" : "Pin") {
                                appModel.toggleCategoryPin(scopeID: scopeID, categoryID: category.id)
                            }
                            .buttonStyle(ScopeInlineActionStyle())

                            Spacer()

                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { appModel.scope(for: scopeID)?.categories.first(where: { $0.id == category.id })?.retrievalEnabled ?? true },
                                    set: { appModel.setCategoryRetrieval(scopeID: scopeID, categoryID: category.id, enabled: $0) }
                                )
                            )
                            .labelsHidden()
                            .tint(ScopeTheme.accent)
                        }
                    }
                }
            }
        }
    }

    private func retrievalSection(for scope: ScopeRecord) -> some View {
        VStack(alignment: .leading, spacing: ScopeTheme.spacingMedium) {
            Text("Retrieval")
                .font(ScopeTheme.sectionTitleFont)
                .foregroundStyle(ScopeTheme.ink)

            card {
                VStack(alignment: .leading, spacing: ScopeTheme.spacingMedium) {
                    Toggle(
                        "Use pinned categories first",
                        isOn: Binding(
                            get: { appModel.scope(for: scopeID)?.preferPinnedCategories ?? true },
                            set: { appModel.setPreferPinnedCategories(scopeID: scopeID, enabled: $0) }
                        )
                    )
                    .tint(ScopeTheme.accent)

                    Toggle(
                        "User-authored first",
                        isOn: Binding(
                            get: { appModel.scope(for: scopeID)?.userAuthoredFirst ?? true },
                            set: { appModel.setUserAuthoredFirst(scopeID: scopeID, enabled: $0) }
                        )
                    )
                    .tint(ScopeTheme.accent)

                    Toggle(
                        "Allow relevant global memory",
                        isOn: Binding(
                            get: { appModel.scope(for: scopeID)?.allowRelevantGlobal ?? false },
                            set: { appModel.setAllowRelevantGlobal(scopeID: scopeID, enabled: $0) }
                        )
                    )
                    .tint(ScopeTheme.accent)
                }
                .font(ScopeTheme.bodyFont)
                .foregroundStyle(ScopeTheme.ink)
            }
        }
    }
}
