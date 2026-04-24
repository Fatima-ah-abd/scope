import SwiftUI

enum ScopeCardStyle {
    case featured
    case compact
}

struct ScopeCardView: View {
    @Environment(AppModel.self) private var appModel

    let scope: ScopeRecord
    var style: ScopeCardStyle = .compact

    private var visual: ScopeThemeSpec {
        ScopeThemeSpec.forScope(scope)
    }

    private var relativeTime: String {
        scope.lastOpenedAt.map { ScopeFormatters.relative.localizedString(for: $0, relativeTo: .now) } ?? "New"
    }

    private var visibleSignals: [ScopeCardSignalRecord] {
        switch style {
        case .featured:
            Array(scope.cardSignals.prefix(3))
        case .compact:
            Array(scope.cardSignals.prefix(2))
        }
    }

    private var contentPadding: CGFloat {
        style == .featured ? 28 : 24
    }

    private var reservedArtworkWidth: CGFloat {
        style == .featured ? 88 : 66
    }

    private var cutoutDiameter: CGFloat {
        style == .featured ? 106 : 76
    }

    private var cutoutOffset: CGFloat {
        cutoutDiameter * 0.5
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardShell

            ScopeGeneratedArtworkView(
                visual: visual,
                style: style == .featured ? .featured : .compact,
                cutoutDiameter: cutoutDiameter
            )
            .offset(x: cutoutOffset, y: -cutoutOffset)

            Group {
                switch style {
                case .featured:
                    featuredCard
                case .compact:
                    compactCard
                }
            }
            .padding(contentPadding)
            .padding(.trailing, reservedArtworkWidth)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var featuredCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(scope.title)
                .font(.system(size: 24, weight: .black, design: .serif))
                .foregroundStyle(visual.homeTitleColor)
                .tracking(-0.35)
                .lineSpacing(-4)
                .fixedSize(horizontal: false, vertical: true)

            Text(scope.summary)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundStyle(visual.homeSummaryColor)
                .fixedSize(horizontal: false, vertical: true)

            if !visibleSignals.isEmpty {
                signalStack
            }

            if appModel.showScopeCardTimestamps, scope.lastOpenedAt != nil {
                timestampLabel
                    .padding(.top, 2)
            }
        }
    }

    private var compactCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(scope.title)
                .font(.system(size: 20, weight: .black, design: .serif))
                .foregroundStyle(visual.homeTitleColor)
                .tracking(-0.2)
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)

            Text(scope.summary)
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundStyle(visual.homeSummaryColor)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)

            if !visibleSignals.isEmpty {
                signalStack
            }

            if appModel.showScopeCardTimestamps, scope.lastOpenedAt != nil {
                timestampLabel
            }
        }
    }

    private var signalStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(visibleSignals) { signal in
                ScopeSignalChipView(
                    signal: signal,
                    fillColor: visual.homeChipFill,
                    textColor: visual.homeChipTextColor
                )
            }
        }
    }

    private var timestampLabel: some View {
        Text(relativeTime)
            .font(ScopeTheme.captionFont.weight(.semibold))
            .foregroundStyle(visual.homeTimestampColor)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private var cardShell: some View {
        RoundedRectangle(cornerRadius: ScopeTheme.radiusCard, style: .continuous)
            .fill(visual.homeCardFill)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color.black)
                    .frame(width: cutoutDiameter, height: cutoutDiameter)
                    .offset(x: cutoutOffset, y: -cutoutOffset)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .shadow(color: visual.homeShadowColor, radius: style == .featured ? 14 : 10, x: 0, y: style == .featured ? 6 : 4)
    }
}

private struct ScopeSignalChipView: View {
    let signal: ScopeCardSignalRecord
    let fillColor: Color
    let textColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 11, weight: .semibold, design: .default))

            Text(displayText)
                .lineLimit(2)
        }
        .font(.system(size: 12, weight: .semibold, design: .default))
        .foregroundStyle(textColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(fillColor, in: RoundedRectangle(cornerRadius: ScopeTheme.radiusChip, style: .continuous))
    }

    private var symbolName: String {
        switch signal.kind {
        case .waitingOnUser:
            "arrow.turn.down.right"
        case .backgroundUpdate:
            "sparkles"
        }
    }

    private var displayText: String {
        switch signal.kind {
        case .waitingOnUser:
            signal.text.replacingOccurrences(of: "Waiting on:", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        case .backgroundUpdate:
            signal.text
        }
    }
}

private enum ScopeArtStyle {
    case featured
    case compact
}

private struct ScopeGeneratedArtworkView: View {
    let visual: ScopeThemeSpec
    let style: ScopeArtStyle
    let cutoutDiameter: CGFloat

    private var lineWeight: CGFloat {
        switch style {
        case .featured:
            0.72
        case .compact:
            0.62
        }
    }

    private var frameSize: CGSize {
        switch style {
        case .featured:
            CGSize(width: 31, height: 31)
        case .compact:
            CGSize(width: 26, height: 26)
        }
    }

    private var leadingInset: CGFloat {
        switch style {
        case .featured:
            21
        case .compact:
            14
        }
    }

    private var bottomInset: CGFloat {
        switch style {
        case .featured:
            20
        case .compact:
            13
        }
    }

    private var backdropSize: CGFloat {
        switch style {
        case .featured:
            56
        case .compact:
            44
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Circle()
                .fill(visual.homeArtBackdrop.opacity(visual.homeArtBackdropOpacity))
                .frame(width: backdropSize, height: backdropSize)
                .padding(.leading, max(leadingInset - 4, 0))
                .padding(.bottom, max(bottomInset - 4, 0))

            ScopeIllustrationView(motif: visual.motif, color: visual.homeArtColor, lineWeight: lineWeight)
                .frame(width: frameSize.width, height: frameSize.height)
                .opacity(style == .featured ? 0.92 : 0.88)
                .padding(.leading, leadingInset)
                .padding(.bottom, bottomInset)
        }
        .frame(width: cutoutDiameter, height: cutoutDiameter, alignment: .bottomLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}
