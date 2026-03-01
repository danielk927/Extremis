import SwiftUI

// MARK: - ChallengesListView

struct ChallengesListView: View {
    var viewModel: IndexViewModel

    /// Novice starts expanded; others collapsed by default.
    @State private var expandedTiers: Set<ChallengeTier> = [.novice]

    var body: some View {
        VStack(spacing: 0) {
            customHeader

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(ChallengeTier.allCases, id: \.self) { tier in
                        TierSection(
                            tier: tier,
                            challenges: ChallengeDatabase.challenges(for: tier),
                            gameState: viewModel.gameState,
                            isExpanded: Binding(
                                get: { expandedTiers.contains(tier) },
                                set: { expanded in
                                    if expanded { expandedTiers.insert(tier) }
                                    else { expandedTiers.remove(tier) }
                                }
                            )
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
        }
        .background(ColorTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var completed: Int {
        ChallengeDatabase.completedCount(for: viewModel.gameState)
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(ColorTheme.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(ColorTheme.border, lineWidth: 1)
                            }
                            .frame(width: 40, height: 40)
                        Image(systemName: "flask")
                            .font(.system(size: 17))
                            .foregroundStyle(ColorTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Challenges")
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .foregroundStyle(ColorTheme.textPrimary)
                        Text("Push your experimental skills.")
                            .font(.system(.caption2))
                            .foregroundStyle(ColorTheme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text("Completed")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(ColorTheme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(completed)")
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(ColorTheme.textPrimary)
                        Text("of \(ChallengeDatabase.all.count)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(ColorTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ColorTheme.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(ColorTheme.border, lineWidth: 1)
                        }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 12)
        .background(ColorTheme.background)
    }
}

// MARK: - Tier Section

private struct TierSection: View {
    var tier: ChallengeTier
    var challenges: [Challenge]
    var gameState: GameState
    @Binding var isExpanded: Bool

    private var completedCount: Int {
        challenges.filter { $0.isCompleted(gameState) }.count
    }

    private var isAllComplete: Bool { completedCount == challenges.count }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 10) {
                ForEach(challenges) { challenge in
                    ChallengeCardView(
                        challenge: challenge,
                        isCompleted: challenge.isCompleted(gameState)
                    )
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 4)
        } label: {
            HStack(spacing: 10) {
                Text(tier.emoji)
                    .font(.system(size: 18))

                Text(tier.displayName)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(ColorTheme.textPrimary)

                if isAllComplete {
                    Text("COMPLETE")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(ColorTheme.accent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(ColorTheme.accent.opacity(0.15))
                        .clipShape(Capsule())
                }

                Spacer()

                Text("\(completedCount)/\(challenges.count)")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(ColorTheme.textSecondary)
            }
        }
        .tint(ColorTheme.textSecondary)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(tier.tintColor)
        )
    }
}
