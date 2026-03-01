import SwiftUI

/// Circular progress ring showing completion as a filled arc.
struct CompletionRingView: View {
    /// Progress from 0.0 (empty) to 1.0 (full).
    var progress: Double
    /// Stroke width of the ring.
    var lineWidth: CGFloat = 4
    /// Diameter of the ring.
    var size: CGFloat = 40
    /// Color of the filled arc.
    var color: Color = ColorTheme.accent

    var body: some View {
        ZStack {
            // Track circle at 10% opacity
            Circle()
                .stroke(color.opacity(0.1), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}
