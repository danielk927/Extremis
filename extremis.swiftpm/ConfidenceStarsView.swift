import SwiftUI

/// Row of 1–5 stars representing a confidence rating.
struct ConfidenceStarsView: View {
    /// Star rating from 1 to 5.
    var rating: Int
    /// Size of each star symbol.
    var size: CGFloat = 16
    /// Whether stars appear with a staggered animation.
    var animated: Bool = false

    @State private var visible = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                let filled = index <= rating
                Image(systemName: filled ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(filled ? ColorTheme.highConfidence : ColorTheme.lowConfidence)
                    .scaleEffect(animated && visible ? 1.0 : (animated ? 0.3 : 1.0))
                    .opacity(animated && !visible ? 0 : 1)
                    .animation(
                        animated
                            ? .spring(response: 0.3, dampingFraction: 0.7)
                                .delay(0.3 * Double(index - 1))
                            : .default,
                        value: visible
                    )
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rating) out of 5 stars")
        .sensoryFeedback(trigger: visible) { _, newValue in
            animated && newValue ? .success : nil
        }
        .onAppear {
            if animated {
                visible = true
            }
        }
    }
}
