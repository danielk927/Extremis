import SwiftUI

/// Tappable pill button with flat light-mode styling.
struct GlassPill: View {
    /// Text label displayed in the pill.
    var label: String
    /// Optional SF Symbol name shown before the label.
    var icon: String? = nil
    /// Whether this pill is in the selected state.
    var isSelected: Bool = false
    /// Accent color applied when selected (unused — accent is always ColorTheme.accent).
    var accentColor: Color = ColorTheme.accent
    /// Tap handler.
    var action: () -> Void = {}

    @State private var tapCount = 0

    var body: some View {
        Button(action: {
            tapCount += 1
            action()
        }) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .accessibilityHidden(true)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(.caption, design: .rounded))
                        .accessibilityHidden(true)
                }

                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : ColorTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(isSelected ? ColorTheme.accent : ColorTheme.background)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : ColorTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "\(label), selected" : label)
        .accessibilityAddTraits(.isButton)
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
    }
}
