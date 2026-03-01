import SwiftUI

struct ChallengeCardView: View {
    var challenge: Challenge
    var isCompleted: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isCompleted
                        ? ColorTheme.accent.opacity(0.12)
                        : ColorTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isCompleted
                                    ? ColorTheme.border
                                    : ColorTheme.border,
                                lineWidth: 1
                            )
                    }
                    .frame(width: 48, height: 48)
                Image(systemName: isCompleted ? "checkmark.seal.fill" : "flask")
                    .font(.system(size: 20))
                    .foregroundStyle(isCompleted ? ColorTheme.accent : ColorTheme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(challenge.name)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ColorTheme.textPrimary)

                Text(challenge.description)
                    .font(.system(.caption))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .lineLimit(2)

                if !isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 10))
                            .foregroundStyle(ColorTheme.textSecondary.opacity(0.6))
                        Text(challenge.requirement)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(ColorTheme.textSecondary.opacity(0.6))
                    }
                }
            }

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ColorTheme.accent)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(ColorTheme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(
                            isCompleted
                                ? ColorTheme.accent.opacity(0.20)
                                : ColorTheme.border,
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 1)
    }
}
