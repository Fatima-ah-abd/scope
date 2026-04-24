import SwiftUI

enum ScopeTheme {
    static let canvas = Color(hex: "EEF6F8")
    static let surface = Color(hex: "FBFDFD")
    static let elevatedSurface = Color(hex: "E8F1F4")
    static let ink = Color(hex: "0B1F3A")
    static let softInk = Color(hex: "133769")
    static let mutedInk = Color(hex: "4E6481")
    static let line = Color(hex: "C2DDE4")
    static let lineStrong = Color(hex: "8EAFC0")

    static let accent = Color(hex: "133769")
    static let accentSecondary = Color(hex: "C9374C")
    static let accentTertiary = Color(hex: "76101E")
    static let accentDeep = Color(hex: "0B1F3A")
    static let tide = accent
    static let moss = accentSecondary
    static let rust = accentTertiary
    static let gold = accentSecondary
    static let blush = Color(hex: "F3F7F8")
    static let mist = Color(hex: "C2DDE4")
    static let actionSurface = mist
    static let shadow = Color.black.opacity(0.06)

    static let radiusCard: CGFloat = 8
    static let radiusChip: CGFloat = 6

    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 16
    static let spacingXLarge: CGFloat = 24

    static let displayFont = Font.system(size: 33, weight: .black, design: .serif)
    static let sectionTitleFont = Font.system(size: 20, weight: .bold, design: .serif)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 12, weight: .regular, design: .default)
    static let eyebrowFont = Font.system(size: 12, weight: .semibold, design: .default)
}

enum ScopeFormatters {
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    static let duration: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()
}

func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(ScopeTheme.spacingLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ScopeTheme.surface, in: RoundedRectangle(cornerRadius: ScopeTheme.radiusCard, style: .continuous))
        .shadow(color: ScopeTheme.shadow.opacity(0.45), radius: 12, x: 0, y: 6)
}

struct ScopePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .default, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, ScopeTheme.spacingLarge)
            .padding(.vertical, 14)
            .background(
                ScopeTheme.accent.opacity(configuration.isPressed ? 0.86 : 1),
                in: RoundedRectangle(cornerRadius: ScopeTheme.radiusCard, style: .continuous)
            )
            .shadow(color: ScopeTheme.accent.opacity(0.18), radius: 10, x: 0, y: 5)
    }
}

struct ScopeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .default, weight: .semibold))
            .foregroundStyle(ScopeTheme.ink)
            .padding(.horizontal, ScopeTheme.spacingLarge)
            .padding(.vertical, 14)
            .background(
                ScopeTheme.surface.opacity(configuration.isPressed ? 0.88 : 1),
                in: RoundedRectangle(cornerRadius: ScopeTheme.radiusCard, style: .continuous)
            )
            .shadow(color: ScopeTheme.shadow.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

struct ScopeTagButtonStyle: ButtonStyle {
    var isEmphasized = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.footnote, design: .default, weight: .medium))
            .foregroundStyle(isEmphasized ? Color.white : ScopeTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                (isEmphasized ? ScopeTheme.accent : ScopeTheme.surface)
                    .opacity(configuration.isPressed ? 0.88 : 1),
                in: RoundedRectangle(cornerRadius: ScopeTheme.radiusChip, style: .continuous)
            )
    }
}

struct ScopeInlineActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.footnote, design: .default, weight: .semibold))
            .foregroundStyle(ScopeTheme.accent.opacity(configuration.isPressed ? 0.72 : 1))
            .padding(.vertical, 4)
    }
}

struct ScopeIconButtonStyle: ButtonStyle {
    var isEmphasized = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .default))
            .foregroundStyle(isEmphasized ? Color.white : ScopeTheme.accentDeep)
            .frame(width: 54, height: 54)
            .background(
                (isEmphasized ? ScopeTheme.accentSecondary : ScopeTheme.actionSurface)
                    .opacity(configuration.isPressed ? 0.88 : 1),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .shadow(color: (isEmphasized ? ScopeTheme.accentSecondary : ScopeTheme.lineStrong).opacity(0.24), radius: 10, x: 0, y: 5)
    }
}

struct StickyActionMenuItem: Identifiable {
    let id = UUID()
    let systemImage: String
    let accessibilityLabel: String
    let foreground: Color
    let background: Color
    let action: () -> Void
}

struct StickyActionMenu: View {
    @Binding var isExpanded: Bool
    let items: [StickyActionMenuItem]

    var body: some View {
        HStack(spacing: 10) {
            if isExpanded {
                ForEach(items) { item in
                    Button {
                        withAnimation(menuAnimation) {
                            isExpanded = false
                        }
                        item.action()
                    } label: {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundStyle(item.foreground)
                            .frame(width: 46, height: 46)
                            .background(item.background, in: Circle())
                    }
                    .accessibilityLabel(item.accessibilityLabel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }
            }

            Button {
                withAnimation(menuAnimation) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundStyle(ScopeTheme.accentDeep)
                    .frame(width: 52, height: 52)
                    .background(ScopeTheme.actionSurface, in: Circle())
                    .shadow(color: ScopeTheme.lineStrong.opacity(0.22), radius: 12, x: 0, y: 6)
            }
            .accessibilityLabel(isExpanded ? "Close menu" : "Open actions")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ScopeTheme.surface.opacity(0.94),
            in: Capsule()
        )
        .shadow(color: ScopeTheme.shadow.opacity(0.38), radius: 16, x: 0, y: 8)
    }

    private var menuAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.84)
    }
}

struct StickyCaptureDock: View {
    let onRecord: () -> Void
    let onCompose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onRecord) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundStyle(Color.white)
                    .frame(width: 50, height: 50)
                    .background(ScopeTheme.accentTertiary, in: Circle())
            }
            .accessibilityLabel("Record")

            Button(action: onCompose) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundStyle(ScopeTheme.accentDeep)
                    .frame(width: 50, height: 50)
                    .background(ScopeTheme.actionSurface, in: Circle())
            }
            .accessibilityLabel("Add")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ScopeTheme.surface.opacity(0.96),
            in: Capsule()
        )
        .shadow(color: ScopeTheme.shadow.opacity(0.38), radius: 16, x: 0, y: 8)
    }
}

struct ScopeBackground: View {
    var body: some View {
        ZStack {
            ScopeTheme.canvas

            LinearGradient(
                colors: [Color.white.opacity(0.75), ScopeTheme.canvas],
                startPoint: .top,
                endPoint: .bottom
            )

            Rectangle()
                .fill(ScopeTheme.accent.opacity(0.025))
                .frame(width: 220, height: 180)
                .blur(radius: 50)
                .offset(x: 150, y: -240)

            Rectangle()
                .fill(ScopeTheme.accentSecondary.opacity(0.02))
                .frame(width: 220, height: 180)
                .blur(radius: 45)
                .offset(x: -160, y: 260)
        }
    }
}

struct ScopeInlineNotice: View {
    let title: String
    let message: String?
    let primaryActionTitle: String?
    let secondaryActionTitle: String?
    let onPrimaryAction: (() -> Void)?
    let onSecondaryAction: (() -> Void)?

    init(
        title: String,
        body: String?,
        primaryActionTitle: String?,
        secondaryActionTitle: String?,
        onPrimaryAction: (() -> Void)?,
        onSecondaryAction: (() -> Void)?
    ) {
        self.title = title
        self.message = body
        self.primaryActionTitle = primaryActionTitle
        self.secondaryActionTitle = secondaryActionTitle
        self.onPrimaryAction = onPrimaryAction
        self.onSecondaryAction = onSecondaryAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(ScopeTheme.bodyFont.weight(.semibold))
                .foregroundStyle(ScopeTheme.ink)

            if let message, !message.isEmpty {
                Text(message)
                    .font(ScopeTheme.captionFont)
                    .foregroundStyle(ScopeTheme.mutedInk)
            }

            if primaryActionTitle != nil || secondaryActionTitle != nil {
                HStack(spacing: 12) {
                    if let primaryActionTitle, let onPrimaryAction {
                        Button(primaryActionTitle, action: onPrimaryAction)
                            .buttonStyle(ScopeInlineActionStyle())
                    }

                    if let secondaryActionTitle, let onSecondaryAction {
                        Button(secondaryActionTitle, action: onSecondaryAction)
                            .buttonStyle(ScopeInlineActionStyle())
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            ScopeTheme.surface.opacity(0.95),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ScopeTheme.line, lineWidth: 1)
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        let red = Double((value & 0xFF0000) >> 16) / 255.0
        let green = Double((value & 0x00FF00) >> 8) / 255.0
        let blue = Double(value & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
