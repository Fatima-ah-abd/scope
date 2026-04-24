import SwiftUI

struct CategoryChipView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(ScopeTheme.captionFont.weight(.medium))
            .foregroundStyle(ScopeTheme.softInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(ScopeTheme.surface, in: RoundedRectangle(cornerRadius: ScopeTheme.radiusChip, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ScopeTheme.radiusChip, style: .continuous)
                    .stroke(ScopeTheme.line, lineWidth: 1)
            }
    }
}
