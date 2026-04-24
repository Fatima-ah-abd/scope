import SwiftUI

struct QuickRecordView: View {
    let preferredScopeID: UUID?

    var body: some View {
        CaptureComposerView(preferredScopeID: preferredScopeID, initialMode: .audio)
    }
}

struct WaveformView: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseline = rect.midY
        path.move(to: CGPoint(x: rect.minX, y: baseline))

        let step = rect.width / 20
        for index in 0...20 {
            let x = rect.minX + (CGFloat(index) * step)
            let phase = CGFloat(index) * 0.65
            let amplitude = (sin(phase) * 24) + (cos(phase * 1.7) * 8)
            path.addLine(to: CGPoint(x: x, y: baseline - amplitude))
        }

        return path
    }
}
