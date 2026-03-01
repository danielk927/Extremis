import SwiftUI

/// Vertical card for the 2-column Species Index grid.
struct OrganismCardView: View {
    var organism: Organism
    var profile: ThermalProfile?
    var isUnlocked: Bool

    var body: some View {
        if isUnlocked {
            unlockedCard
        } else {
            lockedCard
        }
    }

    // MARK: - Unlocked

    private var unlockedCard: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(ColorTheme.accent.opacity(0.10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(ColorTheme.border, lineWidth: 1)
                    }
                    .frame(width: 64, height: 64)
                Image(uiImage: UIImage(named: organism.iconName, in: Bundle.main, compatibleWith: nil) ?? UIImage(systemName: "questionmark.circle")!)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .foregroundStyle(organism.signatureColorValue)
                    .accessibilityHidden(true)
            }

            // Names
            VStack(spacing: 3) {
                Text(organism.commonName)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ColorTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(organism.name)
                    .font(.system(.caption))
                    .italic()
                    .foregroundStyle(ColorTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            // Description
            Text(organism.description)
                .font(.system(.caption))
                .foregroundStyle(ColorTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            // Progress ring + percentage
            VStack(spacing: 3) {
                CompletionRingView(
                    progress: profile?.completionPercentage ?? 0,
                    lineWidth: 3.5,
                    size: 44,
                    color: ColorTheme.accent
                )
                .accessibilityHidden(true)

                Text("\(Int((profile?.completionPercentage ?? 0) * 100))%")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(ColorTheme.textSecondary)
            }

            // Stars — always show 5; filled = earned, outline = not yet
            ConfidenceStarsView(
                rating: profile.flatMap { bestConfidence(from: $0) } ?? 0,
                size: 11,
                animated: false
            )
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(ColorTheme.cardBackground)
        }
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(organism.commonName), unlocked, \(Int((profile?.completionPercentage ?? 0) * 100)) percent complete"
        )
    }

    // MARK: - Locked

    private var lockedCard: some View {
        VStack(spacing: 12) {
            // Lock icon
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(ColorTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(ColorTheme.border, lineWidth: 1)
                    }
                    .frame(width: 64, height: 64)
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(ColorTheme.textSecondary.opacity(0.35))
                    .accessibilityHidden(true)
            }

            // Names
            VStack(spacing: 3) {
                Text(organism.commonName)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(ColorTheme.textSecondary.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("Locked")
                    .font(.system(.caption))
                    .foregroundStyle(ColorTheme.textSecondary.opacity(0.4))
            }

            // Description placeholder (keeps height consistent with unlocked)
            Text(organism.description)
                .font(.system(.caption))
                .foregroundStyle(ColorTheme.textSecondary.opacity(0.25))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .blur(radius: 4)

            // Ring placeholder (keeps height consistent with unlocked)
            VStack(spacing: 3) {
                Circle()
                    .strokeBorder(ColorTheme.border, lineWidth: 3.5)
                    .frame(width: 44, height: 44)
                Text("—")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(ColorTheme.textSecondary.opacity(0.4))
            }

            // Stars placeholder
            ConfidenceStarsView(rating: 0, size: 11, animated: false)
                .opacity(0.25)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(ColorTheme.cardBackground)
        }
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 1)
        .opacity(0.7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(organism.commonName), locked")
    }

    // MARK: - Helpers

    private func bestConfidence(from profile: ThermalProfile) -> Int? {
        let confidences = [
            profile.ctmaxConfidence,
            profile.optimumConfidence,
            profile.acclimationConfidence,
            profile.heatShockConfidence,
            profile.uvResistanceConfidence,
            profile.desiccationToleranceConfidence,
        ].compactMap { $0 }
        return confidences.max()
    }
}
