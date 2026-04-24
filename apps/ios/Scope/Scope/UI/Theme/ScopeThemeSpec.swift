import SwiftUI

enum ScopeArtMotif {
    case storyboard
    case transit
    case strength
    case constellation
    case wave
}

enum ScopeHeroStyle {
    case editorial
    case itinerary
    case ledger
}

enum ScopeSectionLayout {
    case focusFirst
    case memoryFirst
}

struct ScopeThemeSpec {
    let motif: ScopeArtMotif
    let heroStyle: ScopeHeroStyle
    let sectionLayout: ScopeSectionLayout
    let headerLabel: String

    let homeCardFill: Color
    let homeTitleColor: Color
    let homeSummaryColor: Color
    let homeChipFill: Color
    let homeChipTextColor: Color
    let homeArtColor: Color
    let homeArtBackdrop: Color
    let homeArtBackdropOpacity: Double
    let homeTimestampColor: Color
    let homeShadowColor: Color

    let pageCanvas: Color
    let pageGlowPrimary: Color
    let pageGlowSecondary: Color
    let patternColor: Color
    let heroFill: Color
    let heroText: Color
    let heroMutedText: Color
    let surfaceFill: Color
    let elevatedSurfaceFill: Color
    let primaryText: Color
    let secondaryText: Color
    let lineColor: Color
    let accent: Color
    let chipFill: Color
    let chipText: Color
    let shadowColor: Color

    static func forScope(_ scope: ScopeRecord) -> ScopeThemeSpec {
        // Keep theme generation stable for re-entry while the prototype still uses on-device rules.
        let haystack = "\(scope.title) \(scope.summary) \(scope.categoryPreview.joined(separator: " "))".lowercased()

        if haystack.contains("trip") || haystack.contains("travel") || haystack.contains("japan") {
            return ScopeThemeSpec(
                motif: .transit,
                heroStyle: .itinerary,
                sectionLayout: .focusFirst,
                headerLabel: "Plan in motion",
                homeCardFill: Color(hex: "8C3D2F"),
                homeTitleColor: .white,
                homeSummaryColor: Color.white.opacity(0.9),
                homeChipFill: Color.white.opacity(0.16),
                homeChipTextColor: .white,
                homeArtColor: Color(hex: "8C3D2F"),
                homeArtBackdrop: .white,
                homeArtBackdropOpacity: 0.1,
                homeTimestampColor: Color.white.opacity(0.7),
                homeShadowColor: Color(hex: "8C3D2F").opacity(0.22),
                pageCanvas: Color(hex: "F5EEE5"),
                pageGlowPrimary: Color(hex: "E4C8AE"),
                pageGlowSecondary: Color(hex: "CBD9C8"),
                patternColor: Color(hex: "A35A42"),
                heroFill: Color(hex: "8C3D2F"),
                heroText: .white,
                heroMutedText: Color.white.opacity(0.76),
                surfaceFill: Color(hex: "FCF7F1"),
                elevatedSurfaceFill: Color(hex: "F3E7D9"),
                primaryText: Color(hex: "251914"),
                secondaryText: Color(hex: "6A564C"),
                lineColor: Color(hex: "D5C1B3"),
                accent: Color(hex: "8C3D2F"),
                chipFill: Color(hex: "EAD8C8"),
                chipText: Color(hex: "6D2F26"),
                shadowColor: Color(hex: "8C3D2F").opacity(0.16)
            )
        }

        if haystack.contains("train") || haystack.contains("workout") || haystack.contains("strength") {
            return ScopeThemeSpec(
                motif: .strength,
                heroStyle: .ledger,
                sectionLayout: .focusFirst,
                headerLabel: "Current block",
                homeCardFill: Color(hex: "A4373F"),
                homeTitleColor: .white,
                homeSummaryColor: Color.white.opacity(0.9),
                homeChipFill: Color.white.opacity(0.18),
                homeChipTextColor: .white,
                homeArtColor: Color(hex: "A4373F"),
                homeArtBackdrop: .white,
                homeArtBackdropOpacity: 0.1,
                homeTimestampColor: Color.white.opacity(0.7),
                homeShadowColor: Color(hex: "A4373F").opacity(0.2),
                pageCanvas: Color(hex: "F4EEEA"),
                pageGlowPrimary: Color(hex: "E0C3BF"),
                pageGlowSecondary: Color(hex: "D4C2B0"),
                patternColor: Color(hex: "90333B"),
                heroFill: Color(hex: "E9D5D1"),
                heroText: Color(hex: "351A1C"),
                heroMutedText: Color(hex: "6F5151"),
                surfaceFill: Color(hex: "FCF8F6"),
                elevatedSurfaceFill: Color(hex: "F1E1DD"),
                primaryText: Color(hex: "2A1718"),
                secondaryText: Color(hex: "6A5854"),
                lineColor: Color(hex: "D8C6C1"),
                accent: Color(hex: "90333B"),
                chipFill: Color(hex: "E8D5D1"),
                chipText: Color(hex: "6D2D33"),
                shadowColor: Color(hex: "90333B").opacity(0.14)
            )
        }

        if haystack.contains("idea") || haystack.contains("founder") || haystack.contains("product") {
            return ScopeThemeSpec(
                motif: .storyboard,
                heroStyle: .editorial,
                sectionLayout: .memoryFirst,
                headerLabel: "Work in motion",
                homeCardFill: ScopeTheme.accent,
                homeTitleColor: .white,
                homeSummaryColor: Color.white.opacity(0.92),
                homeChipFill: Color.white.opacity(0.16),
                homeChipTextColor: .white,
                homeArtColor: ScopeTheme.accent,
                homeArtBackdrop: .white,
                homeArtBackdropOpacity: 0.08,
                homeTimestampColor: Color.white.opacity(0.72),
                homeShadowColor: ScopeTheme.accent.opacity(0.2),
                pageCanvas: Color(hex: "EEF4F7"),
                pageGlowPrimary: Color(hex: "C9D9E4"),
                pageGlowSecondary: Color(hex: "E4D4C9"),
                patternColor: Color(hex: "1A496D"),
                heroFill: Color(hex: "173D60"),
                heroText: .white,
                heroMutedText: Color.white.opacity(0.76),
                surfaceFill: Color(hex: "FBFCFD"),
                elevatedSurfaceFill: Color(hex: "E7EFF4"),
                primaryText: Color(hex: "10273F"),
                secondaryText: Color(hex: "51657A"),
                lineColor: Color(hex: "C7D8E3"),
                accent: Color(hex: "1A496D"),
                chipFill: Color(hex: "D8E5ED"),
                chipText: Color(hex: "173D60"),
                shadowColor: Color(hex: "1A496D").opacity(0.14)
            )
        }

        let checksum = scope.title.unicodeScalars.reduce(0) { $0 + Int($1.value) }

        if checksum.isMultiple(of: 2) {
            return ScopeThemeSpec(
                motif: .constellation,
                heroStyle: .editorial,
                sectionLayout: .focusFirst,
                headerLabel: "Quiet context",
                homeCardFill: ScopeTheme.surface,
                homeTitleColor: ScopeTheme.accentDeep,
                homeSummaryColor: ScopeTheme.softInk,
                homeChipFill: ScopeTheme.elevatedSurface,
                homeChipTextColor: ScopeTheme.accentDeep,
                homeArtColor: ScopeTheme.accentDeep.opacity(0.72),
                homeArtBackdrop: ScopeTheme.mist,
                homeArtBackdropOpacity: 0.38,
                homeTimestampColor: ScopeTheme.mutedInk,
                homeShadowColor: ScopeTheme.shadow.opacity(0.3),
                pageCanvas: Color(hex: "F3F3EE"),
                pageGlowPrimary: Color(hex: "DADFD6"),
                pageGlowSecondary: Color(hex: "E0D7C6"),
                patternColor: Color(hex: "6C7A6A"),
                heroFill: Color(hex: "E7EBE2"),
                heroText: Color(hex: "1E251D"),
                heroMutedText: Color(hex: "566253"),
                surfaceFill: Color(hex: "FBFCF8"),
                elevatedSurfaceFill: Color(hex: "EEF2E8"),
                primaryText: Color(hex: "21281F"),
                secondaryText: Color(hex: "61695E"),
                lineColor: Color(hex: "D2D8CB"),
                accent: Color(hex: "61705D"),
                chipFill: Color(hex: "E4E9DC"),
                chipText: Color(hex: "42503E"),
                shadowColor: Color(hex: "61705D").opacity(0.12)
            )
        }

        return ScopeThemeSpec(
            motif: .wave,
            heroStyle: .editorial,
            sectionLayout: .focusFirst,
            headerLabel: "Held nearby",
            homeCardFill: ScopeTheme.surface,
            homeTitleColor: ScopeTheme.accentSecondary,
            homeSummaryColor: ScopeTheme.softInk,
            homeChipFill: ScopeTheme.elevatedSurface,
            homeChipTextColor: ScopeTheme.accentDeep,
            homeArtColor: ScopeTheme.accentSecondary.opacity(0.76),
            homeArtBackdrop: ScopeTheme.blush,
            homeArtBackdropOpacity: 0.45,
            homeTimestampColor: ScopeTheme.mutedInk,
            homeShadowColor: ScopeTheme.shadow.opacity(0.3),
            pageCanvas: Color(hex: "F6F0ED"),
            pageGlowPrimary: Color(hex: "E8D4CA"),
            pageGlowSecondary: Color(hex: "D7E1E5"),
            patternColor: Color(hex: "8B5C57"),
            heroFill: Color(hex: "EADAD5"),
            heroText: Color(hex: "2D1D1C"),
            heroMutedText: Color(hex: "6A5553"),
            surfaceFill: Color(hex: "FDF9F7"),
            elevatedSurfaceFill: Color(hex: "F1E3DE"),
            primaryText: Color(hex: "241918"),
            secondaryText: Color(hex: "665755"),
            lineColor: Color(hex: "DDCEC8"),
            accent: Color(hex: "8B5C57"),
            chipFill: Color(hex: "EEDFD9"),
            chipText: Color(hex: "6F4945"),
            shadowColor: Color(hex: "8B5C57").opacity(0.12)
        )
    }
}

enum ScopeSurfaceProminence {
    case standard
    case elevated
}

struct ScopeSurfaceCard<Content: View>: View {
    let theme: ScopeThemeSpec
    var prominence: ScopeSurfaceProminence = .standard
    let content: Content

    init(
        theme: ScopeThemeSpec,
        prominence: ScopeSurfaceProminence = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.theme = theme
        self.prominence = prominence
        self.content = content()
    }

    private var fillColor: Color {
        switch prominence {
        case .standard:
            theme.surfaceFill
        case .elevated:
            theme.elevatedSurfaceFill
        }
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fillColor, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(theme.lineColor, lineWidth: 1)
            }
            .shadow(color: theme.shadowColor.opacity(prominence == .elevated ? 0.34 : 0.24), radius: prominence == .elevated ? 16 : 12, x: 0, y: prominence == .elevated ? 10 : 6)
    }
}

struct ScopePageBackground: View {
    let theme: ScopeThemeSpec

    var body: some View {
        ZStack {
            theme.pageCanvas

            LinearGradient(
                colors: [theme.pageCanvas, Color.white.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )

            ScopePatternField(motif: theme.motif, color: theme.patternColor)
                .opacity(0.26)
                .mask {
                    LinearGradient(
                        colors: [Color.black.opacity(0.88), Color.black.opacity(0.64), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            Circle()
                .fill(theme.pageGlowPrimary.opacity(0.5))
                .frame(width: 280, height: 280)
                .blur(radius: 48)
                .offset(x: 150, y: -230)

            Circle()
                .fill(theme.pageGlowSecondary.opacity(0.46))
                .frame(width: 260, height: 260)
                .blur(radius: 52)
                .offset(x: -150, y: 260)
        }
    }
}

private struct ScopePatternField: View {
    let motif: ScopeArtMotif
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let columnSpacing: CGFloat = 104
            let rowSpacing: CGFloat = 126
            let columns = max(Int(width / columnSpacing) + 2, 4)
            let rows = max(Int(height / rowSpacing) + 2, 7)

            ZStack {
                ForEach(0..<(rows * columns), id: \.self) { index in
                    let row = index / columns
                    let column = index % columns
                    let size = CGFloat(28 + ((row + column) % 3) * 10)
                    let x = CGFloat(column) * columnSpacing + (row.isMultiple(of: 2) ? 26 : 72)
                    let y = CGFloat(row) * rowSpacing + 38
                    let rotation = Double((((row * 9) + (column * 7)) % 5) * 7) - 14

                    ScopeIllustrationView(
                        motif: motif,
                        color: color.opacity((row + column).isMultiple(of: 2) ? 0.95 : 0.72),
                        lineWeight: 0.42
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(rotation))
                    .position(x: x, y: y)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ScopeIllustrationView: View {
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
