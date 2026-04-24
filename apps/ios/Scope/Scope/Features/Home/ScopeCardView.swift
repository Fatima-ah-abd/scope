import SwiftUI

enum ScopeCardStyle {
    case featured
    case compact
}

struct ScopeCardView: View {
    @Environment(AppModel.self) private var appModel

    let scope: ScopeRecord
    var style: ScopeCardStyle = .compact

    private var visual: ScopeVisual {
        ScopeVisual.forScope(scope)
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
                .foregroundStyle(visual.titleColor)
                .tracking(-0.35)
                .lineSpacing(-4)
                .fixedSize(horizontal: false, vertical: true)

            Text(scope.summary)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundStyle(visual.summaryColor)
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
                .foregroundStyle(visual.titleColor)
                .tracking(-0.2)
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)

            Text(scope.summary)
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundStyle(visual.summaryColor)
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
                    fillColor: visual.chipFill,
                    textColor: visual.chipTextColor
                )
            }
        }
    }

    private var timestampLabel: some View {
        Text(relativeTime)
            .font(ScopeTheme.captionFont.weight(.semibold))
            .foregroundStyle(visual.timestampColor)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private var cardShell: some View {
        RoundedRectangle(cornerRadius: ScopeTheme.radiusCard, style: .continuous)
            .fill(visual.cardFill)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color.black)
                    .frame(width: cutoutDiameter, height: cutoutDiameter)
                    .offset(x: cutoutOffset, y: -cutoutOffset)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .shadow(color: visual.shadowColor, radius: style == .featured ? 14 : 10, x: 0, y: style == .featured ? 6 : 4)
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
    let visual: ScopeVisual
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

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ScopeIllustrationView(motif: visual.motif, color: visual.artColor, lineWeight: lineWeight)
                .frame(width: frameSize.width, height: frameSize.height)
                .opacity(style == .featured ? 0.92 : 0.88)
                .padding(.leading, leadingInset)
                .padding(.bottom, bottomInset)
        }
        .frame(width: cutoutDiameter, height: cutoutDiameter, alignment: .bottomLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}

private struct ScopeIllustrationView: View {
    let motif: ScopeArtMotif
    let color: Color
    let lineWeight: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch motif {
                case .storyboard:
                    storyboard(in: geometry.size)
                case .transit:
                    transit(in: geometry.size)
                case .strength:
                    strength(in: geometry.size)
                case .constellation:
                    constellation(in: geometry.size)
                case .wave:
                    wave(in: geometry.size)
                }
            }
            .foregroundStyle(color)
        }
    }

    private func weight(_ base: CGFloat) -> CGFloat {
        base * lineWeight
    }

    private func storyboard(in size: CGSize) -> some View {
        let width = size.width
        let height = size.height

        return ZStack {
            Rectangle()
                .stroke(color, lineWidth: weight(3.4))
                .frame(width: width * 0.7, height: height * 0.44)
                .offset(x: -width * 0.08, y: height * 0.05)

            Rectangle()
                .stroke(color, lineWidth: weight(3.4))
                .frame(width: width * 0.48, height: height * 0.32)
                .offset(x: width * 0.18, y: -height * 0.14)

            SparkShape()
                .stroke(color, style: StrokeStyle(lineWidth: weight(3.1), lineCap: .round, lineJoin: .round))
                .frame(width: width * 0.2, height: width * 0.2)
                .offset(x: width * 0.2, y: height * 0.2)

            Circle()
                .fill(color)
                .frame(width: width * 0.09, height: width * 0.09)
                .offset(x: -width * 0.16, y: -height * 0.2)
        }
    }

    private func transit(in size: CGSize) -> some View {
        let width = size.width
        let height = size.height

        return ZStack {
            Path { path in
                path.move(to: CGPoint(x: width * 0.24, y: height * 0.2))
                path.addLine(to: CGPoint(x: width * 0.24, y: height * 0.82))
            }
            .stroke(style: StrokeStyle(lineWidth: weight(4), lineCap: .round))

            Path { path in
                path.move(to: CGPoint(x: width * 0.24, y: height * 0.45))
                path.addQuadCurve(
                    to: CGPoint(x: width * 0.74, y: height * 0.3),
                    control: CGPoint(x: width * 0.55, y: height * 0.54)
                )
            }
            .stroke(style: StrokeStyle(lineWidth: weight(4), lineCap: .round, lineJoin: .round))

            Path { path in
                path.move(to: CGPoint(x: width * 0.24, y: height * 0.66))
                path.addQuadCurve(
                    to: CGPoint(x: width * 0.72, y: height * 0.78),
                    control: CGPoint(x: width * 0.5, y: height * 0.6)
                )
            }
            .stroke(style: StrokeStyle(lineWidth: weight(4), lineCap: .round, lineJoin: .round))

            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 2) ? color : Color.clear)
                    .overlay {
                        Circle().stroke(color, lineWidth: weight(3))
                    }
                    .frame(width: width * 0.11, height: width * 0.11)
                    .position(transitDotPosition(index: index, size: size))
            }
        }
    }

    private func strength(in size: CGSize) -> some View {
        let width = size.width
        let height = size.height

        return ZStack {
            Path { path in
                path.move(to: CGPoint(x: width * 0.18, y: height * 0.72))
                path.addLine(to: CGPoint(x: width * 0.82, y: height * 0.72))
                path.move(to: CGPoint(x: width * 0.24, y: height * 0.25))
                path.addLine(to: CGPoint(x: width * 0.24, y: height * 0.72))
                path.move(to: CGPoint(x: width * 0.76, y: height * 0.25))
                path.addLine(to: CGPoint(x: width * 0.76, y: height * 0.72))
                path.move(to: CGPoint(x: width * 0.24, y: height * 0.25))
                path.addLine(to: CGPoint(x: width * 0.76, y: height * 0.25))
            }
            .stroke(style: StrokeStyle(lineWidth: weight(4), lineCap: .round, lineJoin: .round))

            Path { path in
                path.move(to: CGPoint(x: width * 0.2, y: height * 0.42))
                path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.42))
            }
            .stroke(style: StrokeStyle(lineWidth: weight(4.6), lineCap: .round))

            ForEach([0.24, 0.32, 0.68, 0.76], id: \.self) { position in
                Rectangle()
                    .fill(color)
                    .frame(width: width * 0.055, height: height * 0.16)
                    .position(x: width * position, y: height * 0.42)
            }

            Circle()
                .fill(color)
                .frame(width: width * 0.075, height: width * 0.075)
                .position(x: width * 0.5, y: height * 0.18)
        }
    }

    private func constellation(in size: CGSize) -> some View {
        let width = size.width
        let height = size.height

        return ZStack {
            Path { path in
                path.move(to: CGPoint(x: width * 0.18, y: height * 0.28))
                path.addLine(to: CGPoint(x: width * 0.56, y: height * 0.2))
                path.addLine(to: CGPoint(x: width * 0.78, y: height * 0.42))
                path.addLine(to: CGPoint(x: width * 0.46, y: height * 0.7))
                path.addLine(to: CGPoint(x: width * 0.2, y: height * 0.56))
            }
            .stroke(style: StrokeStyle(lineWidth: weight(3.2), lineCap: .round, lineJoin: .round))

            ForEach(constellationPoints(in: size), id: \.x) { point in
                Circle()
                    .fill(color)
                    .frame(width: width * 0.075, height: width * 0.075)
                    .position(point)
            }
        }
    }

    private func wave(in size: CGSize) -> some View {
        let width = size.width
        let height = size.height

        return ZStack {
            ForEach(0..<3, id: \.self) { index in
                Path { path in
                    let y = height * (0.3 + (CGFloat(index) * 0.18))
                    path.move(to: CGPoint(x: width * 0.12, y: y))
                    path.addCurve(
                        to: CGPoint(x: width * 0.88, y: y),
                        control1: CGPoint(x: width * 0.32, y: y - 18),
                        control2: CGPoint(x: width * 0.62, y: y + 18)
                    )
                }
                .stroke(style: StrokeStyle(lineWidth: weight(4), lineCap: .round, lineJoin: .round))
            }

            Circle()
                .fill(color)
                .frame(width: width * 0.09, height: width * 0.09)
                .offset(x: width * 0.2, y: -height * 0.24)
        }
    }

    private func transitDotPosition(index: Int, size: CGSize) -> CGPoint {
        switch index {
        case 0:
            CGPoint(x: size.width * 0.24, y: size.height * 0.2)
        case 1:
            CGPoint(x: size.width * 0.74, y: size.height * 0.3)
        case 2:
            CGPoint(x: size.width * 0.24, y: size.height * 0.66)
        default:
            CGPoint(x: size.width * 0.72, y: size.height * 0.78)
        }
    }

    private func constellationPoints(in size: CGSize) -> [CGPoint] {
        [
            CGPoint(x: size.width * 0.18, y: size.height * 0.28),
            CGPoint(x: size.width * 0.56, y: size.height * 0.2),
            CGPoint(x: size.width * 0.78, y: size.height * 0.42),
            CGPoint(x: size.width * 0.46, y: size.height * 0.7),
            CGPoint(x: size.width * 0.2, y: size.height * 0.56),
        ]
    }
}

private struct SparkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.move(to: CGPoint(x: center.x, y: rect.minY))
        path.addLine(to: CGPoint(x: center.x, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: center.y))
        path.addLine(to: CGPoint(x: rect.maxX, y: center.y))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.maxY - rect.height * 0.2))
        path.move(to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY + rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY - rect.height * 0.2))

        return path
    }
}

private enum ScopeArtMotif {
    case storyboard
    case transit
    case strength
    case constellation
    case wave
}

private struct ScopeVisual {
    let motif: ScopeArtMotif
    let cardFill: Color
    let titleColor: Color
    let summaryColor: Color
    let chipFill: Color
    let chipTextColor: Color
    let artColor: Color
    let artBackdrop: Color
    let artBackdropOpacity: Double
    let timestampColor: Color
    let shadowColor: Color

    static func forScope(_ scope: ScopeRecord) -> ScopeVisual {
        let haystack = "\(scope.title) \(scope.summary) \(scope.categoryPreview.joined(separator: " "))".lowercased()

        if haystack.contains("trip") || haystack.contains("travel") || haystack.contains("japan") {
            return ScopeVisual(
                motif: .transit,
                cardFill: ScopeTheme.accentTertiary,
                titleColor: Color.white,
                summaryColor: Color.white.opacity(0.9),
                chipFill: Color.white.opacity(0.16),
                chipTextColor: Color.white,
                artColor: ScopeTheme.accentTertiary,
                artBackdrop: Color.white,
                artBackdropOpacity: 0.08,
                timestampColor: Color.white.opacity(0.68),
                shadowColor: ScopeTheme.accentTertiary.opacity(0.18)
            )
        }

        if haystack.contains("train") || haystack.contains("workout") || haystack.contains("strength") {
            return ScopeVisual(
                motif: .strength,
                cardFill: ScopeTheme.accentSecondary,
                titleColor: Color.white,
                summaryColor: Color.white.opacity(0.9),
                chipFill: Color.white.opacity(0.18),
                chipTextColor: Color.white,
                artColor: ScopeTheme.accentSecondary,
                artBackdrop: Color.white,
                artBackdropOpacity: 0.08,
                timestampColor: Color.white.opacity(0.68),
                shadowColor: ScopeTheme.accentSecondary.opacity(0.18)
            )
        }

        if haystack.contains("idea") || haystack.contains("founder") || haystack.contains("product") {
            return ScopeVisual(
                motif: .storyboard,
                cardFill: ScopeTheme.accent,
                titleColor: Color.white,
                summaryColor: Color.white.opacity(0.92),
                chipFill: Color.white.opacity(0.16),
                chipTextColor: Color.white,
                artColor: ScopeTheme.accent,
                artBackdrop: Color.white,
                artBackdropOpacity: 0.06,
                timestampColor: Color.white.opacity(0.7),
                shadowColor: ScopeTheme.accent.opacity(0.18)
            )
        }

        let checksum = scope.title.unicodeScalars.reduce(0) { $0 + Int($1.value) }

        switch checksum % 2 {
        case 0:
            return ScopeVisual(
                motif: .constellation,
                cardFill: ScopeTheme.surface,
                titleColor: ScopeTheme.accentDeep,
                summaryColor: ScopeTheme.softInk,
                chipFill: ScopeTheme.elevatedSurface,
                chipTextColor: ScopeTheme.accentDeep,
                artColor: ScopeTheme.accentDeep.opacity(0.72),
                artBackdrop: ScopeTheme.mist,
                artBackdropOpacity: 0.35,
                timestampColor: ScopeTheme.mutedInk,
                shadowColor: ScopeTheme.shadow.opacity(0.3)
            )
        default:
            return ScopeVisual(
                motif: .wave,
                cardFill: ScopeTheme.surface,
                titleColor: ScopeTheme.accentSecondary,
                summaryColor: ScopeTheme.softInk,
                chipFill: ScopeTheme.elevatedSurface,
                chipTextColor: ScopeTheme.accentDeep,
                artColor: ScopeTheme.accentSecondary.opacity(0.76),
                artBackdrop: ScopeTheme.blush,
                artBackdropOpacity: 0.45,
                timestampColor: ScopeTheme.mutedInk,
                shadowColor: ScopeTheme.shadow.opacity(0.3)
            )
        }
    }
}
