import SwiftUI

struct CreateScopeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ScopeTheme.spacingLarge) {
                    Text("New scope")
                        .font(ScopeTheme.displayFont)
                        .foregroundStyle(ScopeTheme.ink)

                    VStack(alignment: .leading, spacing: ScopeTheme.spacingSmall) {
                        Text("Name")
                            .font(ScopeTheme.captionFont.weight(.medium))
                            .foregroundStyle(ScopeTheme.mutedInk)

                        TextField("Founder Ideas", text: $title)
                            .textInputAutocapitalization(.words)
                            .padding(14)
                            .background(ScopeTheme.surface, in: RoundedRectangle(cornerRadius: ScopeTheme.radiusCard))
                            .overlay {
                                RoundedRectangle(cornerRadius: ScopeTheme.radiusCard)
                                    .stroke(ScopeTheme.line, lineWidth: 1)
                            }
                    }

                    VStack(alignment: .leading, spacing: ScopeTheme.spacingSmall) {
                        Text("Optional note")
                            .font(ScopeTheme.captionFont.weight(.medium))
                            .foregroundStyle(ScopeTheme.mutedInk)

                        TextField("Products, positioning, early experiments", text: $note, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .padding(14)
                            .background(ScopeTheme.surface, in: RoundedRectangle(cornerRadius: ScopeTheme.radiusCard))
                            .overlay {
                                RoundedRectangle(cornerRadius: ScopeTheme.radiusCard)
                                    .stroke(ScopeTheme.line, lineWidth: 1)
                            }
                    }

                    VStack(alignment: .leading, spacing: ScopeTheme.spacingSmall) {
                        Text("Starter categories")
                            .font(ScopeTheme.captionFont.weight(.medium))
                            .foregroundStyle(ScopeTheme.mutedInk)

                        HStack(spacing: ScopeTheme.spacingSmall) {
                            ForEach(previewCategories, id: \.self) { category in
                                CategoryChipView(title: category)
                            }
                        }
                    }

                    Button("Create scope") {
                        _ = appModel.createScope(title: title, note: note)
                        dismiss()
                    }
                    .buttonStyle(ScopePrimaryButtonStyle())
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, ScopeTheme.spacingLarge)
                .padding(.vertical, ScopeTheme.spacingXLarge)
            }
            .background {
                ScopeBackground().ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var previewCategories: [String] {
        let trimmed = "\(title) \(note)".lowercased()

        if trimmed.contains("idea") || trimmed.contains("founder") || trimmed.contains("product") {
            return ["products", "audiences", "experiments"]
        }

        if trimmed.contains("trip") || trimmed.contains("travel") {
            return ["dates", "lodging", "ideas"]
        }

        return ["notes", "ideas", "next"]
    }
}
