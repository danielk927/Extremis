import SwiftUI

/// Results screen shown after the experiment animation completes.
/// "Log to Index" saves the result, runs unlock checks, and returns to the Index.
/// "Try Again" returns to the designer with the same configuration.
struct PostExperimentView: View {
    var result: ExperimentResult
    var organism: Organism
    var experimentVM: ExperimentViewModel
    var indexViewModel: IndexViewModel

    /// Called by "Try Again" so ExperimentRunnerView can also dismiss itself.
    var onTryAgain: (() -> Void)? = nil

    @State private var hasLogged = false
    @State private var pendingOrganisms: [Organism] = []
    @State private var pendingHandbookKeys: [String] = []
    @Environment(\.dismiss) private var dismiss

    private var gameState: GameState { indexViewModel.gameState }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                resultValueSection
                chartSection
                relevanceCard
                feedbackSection
                if !pendingOrganisms.isEmpty || !pendingHandbookKeys.isEmpty {
                    unlockBanner
                }
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .background(ColorTheme.background.ignoresSafeArea())
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { computePendingUnlocks() }
        .sensoryFeedback(trigger: hasLogged) { _, newValue in
            newValue && !pendingOrganisms.isEmpty ? .impact(weight: .heavy) : nil
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 14) {
            Image(uiImage: UIImage(named: organism.iconName, in: Bundle.main, compatibleWith: nil) ?? UIImage(systemName: "questionmark.circle")!)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundStyle(organism.signatureColorValue)

            Text(organism.commonName)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(ColorTheme.textPrimary)

            Text(result.researchQuestion.displayName.uppercased())
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(ColorTheme.textSecondary)
                .tracking(1.5)

            ConfidenceStarsView(rating: result.confidenceRating, size: 28, animated: true)

            Text(qualityLabel(result.confidenceRating))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(confidenceColor(result.confidenceRating))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(ColorTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(ColorTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Result Value

    private var resultValueSection: some View {
        let unit = result.researchQuestion.measuredValueUnit
        return VStack(spacing: 6) {
            if result.confidenceRating >= 3 {
                // Precise: show exact value
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(result.measuredValue, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: 52, design: .monospaced).weight(.bold))
                        .foregroundStyle(ColorTheme.textPrimary)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(.title2, design: .monospaced))
                            .foregroundStyle(ColorTheme.textSecondary)
                    }
                }
                Text("± \(result.errorMargin, specifier: "%.1f") \(unit)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(ColorTheme.textSecondary)
            } else {
                // Low confidence: show approximate range
                let lo = result.measuredValue - result.errorMargin
                let hi = result.measuredValue + result.errorMargin
                Text(unit.isEmpty
                    ? String(format: "~ %.2f – %.2f", lo, hi)
                    : String(format: "~ %.0f – %.0f \(unit)", lo, hi))
                    .font(.system(size: 40, design: .monospaced).weight(.bold))
                    .foregroundStyle(ColorTheme.textPrimary)
                Text("Wide margin — low-confidence result")
                    .font(.system(.caption))
                    .foregroundStyle(ColorTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(ColorTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Chart

    private var chartSection: some View {
        // Match LiveChartView's internal margin (m = 8) for tick alignment
        let chartH: CGFloat = 160
        let m: CGFloat = 8
        let plotH = chartH - m * 2        // 144
        let tickInterval = plotH / 4      // 36 — gap between the 5 y-ticks
        let yLabelW: CGFloat = 12         // width of rotated DV name label
        let yAxisW: CGFloat = 32          // width of numeric tick column
        let dv = result.dependentVariable

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(result.dynamicChartTitle)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(ColorTheme.textPrimary)
                Spacer()
                Text("n = \(experimentVM.sampleSize)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(ColorTheme.textSecondary)
            }

            // Axes + chart canvas
            HStack(alignment: .top, spacing: 0) {
                // Rotated y-axis label (DV name, reads bottom-to-top)
                Text(dv.displayName)
                    .font(.system(size: 8, design: .rounded))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .lineLimit(1)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
                    .frame(width: yLabelW, height: chartH)

                // Y-axis tick labels (scale/unit follow chosen DV)
                VStack(spacing: 0) {
                    Spacer().frame(height: max(0, m - 7))
                    ForEach(dv.yAxisTicks.indices, id: \.self) { idx in
                        Text(dv.yAxisTicks[idx])
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(ColorTheme.textSecondary)
                            .frame(height: 14)
                        if idx < dv.yAxisTicks.count - 1 {
                            Spacer().frame(height: max(0, tickInterval - 14))
                        }
                    }
                    Spacer()
                }
                .frame(width: yAxisW, height: chartH)

                // Chart canvas
                LiveChartView(
                    points: result.rawDataPoints,
                    organism: organism,
                    researchQuestion: result.researchQuestion,
                    independentVariable: result.independentVariable
                )
                .frame(height: chartH)
                .background(ColorTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // X-axis label (offset left by full y-axis area to center under the chart)
            HStack(spacing: 0) {
                Spacer().frame(width: yLabelW + yAxisW)
                Text(result.independentVariable.axisLabel)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Relevance Card

    private var relevanceCard: some View {
        let isValidIV  = result.researchQuestion.ivCredit(for: result.independentVariable) == 2
        let isRelevant = result.isRelevantCombination
        let ivName = result.independentVariable.displayName
        let dvName = result.dependentVariable.displayName
        let qName  = result.researchQuestion.displayName.lowercased()

        let title  = isRelevant ? "Informative Experiment" : "Variable Mismatch"
        let icon   = isRelevant ? "checkmark.circle.fill"  : "exclamationmark.triangle.fill"
        let accentColor = isRelevant ? ColorTheme.accent   : ColorTheme.star

        let message: String
        if isRelevant {
            message = "Varying \(ivName) and measuring \(dvName) is a valid approach for studying \(qName). The data shows a clear biological pattern."
        } else if !isValidIV {
            message = "Varying \(ivName) and measuring \(dvName) doesn't reveal \(qName). The graph shows scattered, patternless data — this variable doesn't drive the biological response you're investigating."
        } else {
            message = "You varied the right thing (\(ivName)), but \(dvName) isn't the best measure for \(qName). The pattern may be weak or misleading."
        }

        let hint: String? = isRelevant ? nil : relevanceHint(isValidIV: isValidIV)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ColorTheme.textPrimary)
            }
            Text(message)
                .font(.system(.subheadline))
                .foregroundStyle(ColorTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let hint {
                Text(hint)
                    .font(.system(.caption))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .strokeBorder(accentColor.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func relevanceHint(isValidIV: Bool) -> String {
        if !isValidIV {
            // Mention all valid IV options for this question
            if result.researchQuestion == .desiccationTolerance {
                return "💡 Try \"Exposure Duration\" or \"Humidity\" as your independent variable to reveal the desiccation tolerance relationship."
            }
            let correctIV = result.researchQuestion.correctIndependentVariable.displayName
            return "💡 Try \"\(correctIV)\" as your independent variable to reveal the \(result.researchQuestion.displayName.lowercased()) relationship."
        } else {
            return "💡 Try \"\(bestDVName(for: result.researchQuestion))\" as your dependent variable for the clearest signal."
        }
    }

    private func bestDVName(for question: ResearchQuestion) -> String {
        switch question {
        case .ctmax, .acclimationCapacity, .uvResistance, .desiccationTolerance:
            return DependentVariable.survivalRate.displayName
        case .thermalOptimum:
            return DependentVariable.movementSpeed.displayName
        case .heatShockResponse:
            return DependentVariable.proteinActivity.displayName
        }
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feedback")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(ColorTheme.textPrimary)
            VStack(spacing: 12) {
                ForEach(Array(result.feedbackItems.enumerated()), id: \.offset) { _, item in
                    PostFeedbackRow(item: item)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Unlock Banner

    private var unlockBanner: some View {
        VStack(spacing: 8) {
            ForEach(pendingOrganisms) { org in
                UnlockBannerRow(
                    icon: org.iconName,
                    color: org.signatureColorValue,
                    message: "New organism unlocked: \(org.commonName)!",
                    isSystemIcon: false
                )
            }
            ForEach(pendingHandbookKeys, id: \.self) { key in
                if let entry = HandbookViewModel.allEntries.first(where: { $0.id == key }) {
                    UnlockBannerRow(
                        icon: entry.icon,
                        color: entry.accentColor,
                        message: "Handbook entry unlocked: \(entry.title)"
                    )
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Try Again
            Button {
                onTryAgain?()
                dismiss()
            } label: {
                Label("Try Again", systemImage: "arrow.counterclockwise")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ColorTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ColorTheme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(ColorTheme.border, lineWidth: 1)
                            )
                    )
            }

            // Log to Index
            Button {
                logAndReturn()
            } label: {
                Label("Log to Index", systemImage: "square.grid.2x2")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(hasLogged ? ColorTheme.textSecondary : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(hasLogged
                                ? ColorTheme.cardBackground
                                : ColorTheme.accent)
                    )
            }
            .disabled(hasLogged)
        }
    }

    // MARK: - Logging

    private func logAndReturn() {
        guard !hasLogged else { return }
        hasLogged = true

        // 1. Log experiment result (updates profile fields + increments counters)
        gameState.logExperiment(result, for: organism.id)

        // 2. Unlock new organisms
        let newOrgs = ExperimentEngine.checkOrganismUnlocks(
            gameState: gameState, allOrganisms: indexViewModel.allOrganisms)
        for org in newOrgs {
            gameState.unlockedOrganismIds.insert(org.id)
        }

        // 3. Unlock handbook entries
        if let experiment = experimentVM.lastExperiment {
            let newKeys = ExperimentEngine.checkHandbookUnlocks(
                experiment: experiment, result: result, organism: organism, gameState: gameState)
            for key in newKeys {
                gameState.unlockedHandbookEntries.insert(key)
            }
        }

        // 4. Persist
        gameState.save()

        // 5. Pop entire Index navigation stack back to root
        indexViewModel.navigationPath = []
    }

    // MARK: - Pre-compute pending unlocks (shown before logging)

    private func computePendingUnlocks() {
        pendingOrganisms = ExperimentEngine.checkOrganismUnlocks(
            gameState: gameState, allOrganisms: indexViewModel.allOrganisms)
        if let experiment = experimentVM.lastExperiment {
            pendingHandbookKeys = ExperimentEngine.checkHandbookUnlocks(
                experiment: experiment, result: result, organism: organism, gameState: gameState)
        }
    }

    // MARK: - Helpers

    private func qualityLabel(_ r: Int) -> String {
        switch r {
        case 5: return "Excellent Design"
        case 4: return "Good Design"
        case 3: return "Fair Design"
        case 2: return "Needs Improvement"
        default: return "Poor Design"
        }
    }

    private func confidenceColor(_ r: Int) -> Color {
        r >= 3 ? ColorTheme.accent : ColorTheme.textSecondary
    }
}

// MARK: - Feedback Row

private struct PostFeedbackRow: View {
    var item: FeedbackItem

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Colored left border
            Rectangle()
                .fill(item.isPositive ? ColorTheme.accent : ColorTheme.textSecondary)
                .frame(width: 3)
                .clipShape(Capsule())
                .padding(.vertical, 2)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.isPositive ? "checkmark.circle" : "lightbulb")
                    .font(.system(size: 16))
                    .foregroundStyle(item.isPositive ? ColorTheme.accent : ColorTheme.textSecondary)
                    .frame(width: 20)
                    .padding(.top, 1)
                Text(item.message)
                    .font(.system(.subheadline))
                    .foregroundStyle(ColorTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(item.isPositive
                    ? ColorTheme.accent.opacity(0.08)
                    : ColorTheme.border.opacity(0.25))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Unlock Banner Row

private struct UnlockBannerRow: View {
    var icon: String
    var color: Color
    var message: String
    var isSystemIcon: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                } else {
                    Image(uiImage: UIImage(named: icon, in: Bundle.main, compatibleWith: nil) ?? UIImage(systemName: "questionmark.circle")!)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
            }
            .foregroundStyle(ColorTheme.accent)
            .frame(width: 28)
            Text(message)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ColorTheme.textPrimary)
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundStyle(ColorTheme.star)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ColorTheme.accent.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(ColorTheme.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
