import SwiftUI

/// Detail page for a single organism showing its thermal profile and experiment history.
struct OrganismDetailView: View {
    var organism: Organism
    var viewModel: IndexViewModel

    @State private var showDesigner = false
    @State private var designerQuestion: ResearchQuestion = .ctmax

    private var profile: ThermalProfile {
        viewModel.profileFor(organism)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                heroSection
                dataFieldsSection
                if !profile.experimentHistory.isEmpty {
                    historySection
                }
                if profile.isComplete {
                    funFactSection
                }
            }
            .padding(.bottom, 32)
        }
        .background(ColorTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    designerQuestion = .ctmax
                    showDesigner = true
                } label: {
                    Label("Run Experiment", systemImage: "flask")
                }
            }
        }
        .navigationDestination(isPresented: $showDesigner) {
            ExperimentDesignerView(
                organism: organism,
                initialQuestion: designerQuestion,
                viewModel: viewModel
            )
        }
    }

    private func investigate(_ question: ResearchQuestion) {
        designerQuestion = question
        showDesigner = true
    }
}

// MARK: - Hero Section

private extension OrganismDetailView {
    var heroSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(ColorTheme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(ColorTheme.border, lineWidth: 1)
                }

            VStack(spacing: 16) {
                Image(uiImage: UIImage(named: organism.iconName, in: Bundle.main, compatibleWith: nil) ?? UIImage(systemName: "questionmark.circle")!)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .foregroundStyle(ColorTheme.textPrimary)
                    .accessibilityHidden(true)

                VStack(spacing: 4) {
                    Text(organism.commonName)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(ColorTheme.textPrimary)

                    Text(organism.name)
                        .font(.system(.subheadline, design: .rounded))
                        .italic()
                        .foregroundStyle(ColorTheme.textSecondary)
                }

                CompletionRingView(
                    progress: profile.completionPercentage,
                    lineWidth: 6,
                    size: 80,
                    color: organism.signatureColorValue
                )

                Text("\(Int(profile.completionPercentage * 100))% Complete")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(ColorTheme.textSecondary)
            }
            .padding(.vertical, 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Data Fields Section

private extension OrganismDetailView {
    var dataFieldsSection: some View {
        VStack(spacing: 12) {
            Text("Biological Profile")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(ColorTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                DataFieldRow(
                    fieldName: ResearchQuestion.ctmax.displayName,
                    sfSymbol: "thermometer.high",
                    discoveredValue: profile.discoveredCTMax.map { DataFieldRow.formatTemperature($0) },
                    confidence: profile.ctmaxConfidence,
                    unit: "°C",
                    onInvestigate: { investigate(.ctmax) }
                )

                DataFieldRow(
                    fieldName: ResearchQuestion.thermalOptimum.displayName,
                    sfSymbol: "gauge.medium",
                    discoveredValue: profile.discoveredOptimum.map { DataFieldRow.formatTemperature($0) },
                    confidence: profile.optimumConfidence,
                    unit: "°C",
                    onInvestigate: { investigate(.thermalOptimum) }
                )

                DataFieldRow(
                    fieldName: ResearchQuestion.acclimationCapacity.displayName,
                    sfSymbol: "arrow.triangle.2.circlepath",
                    discoveredValue: profile.discoveredAcclimation.map { DataFieldRow.formatScaleValue($0) },
                    confidence: profile.acclimationConfidence,
                    unit: "",
                    onInvestigate: { investigate(.acclimationCapacity) }
                )

                DataFieldRow(
                    fieldName: ResearchQuestion.heatShockResponse.displayName,
                    sfSymbol: "shield.lefthalf.filled",
                    discoveredValue: profile.discoveredHeatShock.map { DataFieldRow.formatScaleValue($0) },
                    confidence: profile.heatShockConfidence,
                    unit: "",
                    onInvestigate: { investigate(.heatShockResponse) }
                )

                DataFieldRow(
                    fieldName: ResearchQuestion.uvResistance.displayName,
                    sfSymbol: "sun.max",
                    discoveredValue: profile.discoveredUVResistance.map { DataFieldRow.formatScaleValue($0) },
                    confidence: profile.uvResistanceConfidence,
                    unit: "",
                    onInvestigate: { investigate(.uvResistance) }
                )

                DataFieldRow(
                    fieldName: ResearchQuestion.desiccationTolerance.displayName,
                    sfSymbol: "humidity",
                    discoveredValue: profile.discoveredDesiccationTolerance.map { DataFieldRow.formatScaleValue($0) },
                    confidence: profile.desiccationToleranceConfidence,
                    unit: "",
                    onInvestigate: { investigate(.desiccationTolerance) }
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - History Section

private extension OrganismDetailView {
    var historySection: some View {
        VStack(spacing: 12) {
            DisclosureGroup {
                VStack(spacing: 8) {
                    ForEach(profile.experimentHistory.reversed()) { result in
                        HistoryRow(result: result)
                    }
                }
                .padding(.top, 8)
            } label: {
                Text("Past Experiments (\(profile.experimentHistory.count))")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(ColorTheme.textPrimary)
            }
            .tint(ColorTheme.textSecondary)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Fun Fact Section

private extension OrganismDetailView {
    var funFactSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Fun Fact", systemImage: "lightbulb")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(ColorTheme.accent)

            Text(organism.funFact)
                .font(.system(.body))
                .foregroundStyle(ColorTheme.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ColorTheme.accent.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(ColorTheme.accent.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - History Row

private struct HistoryRow: View {
    var result: ExperimentResult

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.measuredValue, format: .number.precision(.fractionLength(1)))
                    .font(.system(.body, design: .monospaced, weight: .bold))
                    .foregroundStyle(ColorTheme.textPrimary)

                Text("± \(result.errorMargin, specifier: "%.1f")")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(ColorTheme.textSecondary)
            }

            Spacer()

            ConfidenceStarsView(rating: result.confidenceRating, size: 10)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ColorTheme.cardBackground)
        )
    }
}
