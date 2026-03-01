import SwiftUI

/// Carries the title and body text for the info sheet shown when a step's ⓘ is tapped.
private struct StepInfo: Identifiable {
    let id: Int   // step number — guaranteed unique across the five steps
    let title: String
    let text: String
}

/// The core teaching interaction — a five-step experiment design screen.
struct ExperimentDesignerView: View {
    var organism: Organism
    var initialQuestion: ResearchQuestion
    var viewModel: IndexViewModel

    @State private var experimentVM: ExperimentViewModel
    @State private var activeInfo: StepInfo? = nil
    @State private var navigateToRunner = false
    @State private var runTapCount = 0

    init(organism: Organism, initialQuestion: ResearchQuestion, viewModel: IndexViewModel) {
        self.organism = organism
        self.initialQuestion = initialQuestion
        self.viewModel = viewModel
        _experimentVM = State(
            initialValue: ExperimentViewModel(organism: organism, question: initialQuestion)
        )
    }

    private var isFirstTime: Bool { !viewModel.gameState.firstExperimentComplete }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                contextCard
                ivSection
                dvSection
                controlledVarsSection
                controlGroupSection
                sampleSizeSection
                runButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(ColorTheme.background.ignoresSafeArea())
        .navigationTitle(organism.commonName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeInfo) { info in
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Text(info.title)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(ColorTheme.textPrimary)
                    Spacer()
                    Button { activeInfo = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(ColorTheme.textSecondary)
                    }
                }
                Text(info.text)
                    .font(.system(.body))
                    .foregroundStyle(ColorTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(ColorTheme.background.ignoresSafeArea())
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $navigateToRunner) {
            ExperimentRunnerView(experimentVM: experimentVM, indexViewModel: viewModel)
        }
    }
}

// MARK: - Context Card

private extension ExperimentDesignerView {
    var contextCard: some View {
        HStack(spacing: 14) {
            Image(uiImage: UIImage(named: organism.iconName, in: Bundle.main, compatibleWith: nil) ?? UIImage(systemName: "questionmark.circle")!)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .foregroundStyle(organism.signatureColorValue)

            VStack(alignment: .leading, spacing: 4) {
                Text(questionPlainText(initialQuestion))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ColorTheme.textPrimary)

                Text(questionDefinition(initialQuestion))
                    .font(.system(.caption))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(ColorTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Step 1: Independent Variable

private extension ExperimentDesignerView {
    var ivSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader(
                step: 1,
                title: "What will you change?",
                infoText: "The independent variable is the one factor you deliberately change. This is to see how the organism responds to that change."
            )

            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(IndependentVariable.allCases) { iv in
                    GlassPill(
                        label: iv.displayName,
                        icon: ivSymbol(iv),
                        isSelected: experimentVM.independentVariable == iv,
                        accentColor: ColorTheme.accent,
                        action: { experimentVM.independentVariable = iv }
                    )
                    .frame(maxWidth: .infinity)
                }
            }

            if isFirstTime {
                Text(ivTip)
                    .font(.system(.caption))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .italic()
            }
        }
    }
}

// MARK: - Step 2: Dependent Variable

private extension ExperimentDesignerView {
    var dvSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader(
                step: 2,
                title: "What will you measure?",
                infoText: "The dependent variable is what you observe or measure in response to your manipulation. It should directly reflect the process you're studying."
            )

            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(DependentVariable.allCases) { dv in
                    GlassPill(
                        label: dv.displayName,
                        icon: dvSymbol(dv),
                        isSelected: experimentVM.dependentVariable == dv,
                        accentColor: ColorTheme.accent,
                        action: { experimentVM.dependentVariable = dv }
                    )
                    .frame(maxWidth: .infinity)
                }
            }

            if isFirstTime {
                Text(dvTip)
                    .font(.system(.caption))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .italic()
            }
        }
    }
}

// MARK: - Step 3: Controlled Variables

private extension ExperimentDesignerView {
    var controlledVarsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader(
                step: 3,
                title: "What will you keep constant?",
                infoText: "Controlled variables are factors you hold constant so they can't influence your results. Uncontrolled factors that affect the organism create noise and confound your data."
            )

            let columns = [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(ControlledVariable.allCases) { cv in
                    GlassPill(
                        label: cv.displayName,
                        icon: cvSymbol(cv),
                        isSelected: experimentVM.controlledVariables.contains(cv),
                        accentColor: ColorTheme.accent,
                        action: { experimentVM.toggleControlledVariable(cv) }
                    )
                    .frame(maxWidth: .infinity)
                }
            }

            if isFirstTime {
                Text("Tip: Some organisms have known sensitivities. Discover them through experimentation.")
                    .font(.system(.caption))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .italic()
            }
        }
    }
}

// MARK: - Step 4: Control Group

private extension ExperimentDesignerView {
    var controlGroupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader(
                step: 4,
                title: "Include a control group?",
                infoText: "A control group is kept at a baseline condition. Without one, you can't confirm that differences in your results are caused by your independent variable rather than random variation."
            )

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Room-temperature control group (22°C)")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(ColorTheme.textPrimary)
                    Text("Provides a baseline for comparison")
                        .font(.system(.caption))
                        .foregroundStyle(ColorTheme.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $experimentVM.hasControlGroup)
                    .tint(ColorTheme.accent)
                    .labelsHidden()
            }
            .padding(16)
            .background(ColorTheme.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(ColorTheme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            if isFirstTime {
                Text("Tip: A control group lets you verify the effect is due to your variable, not random chance.")
                    .font(.system(.caption))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .italic()
            }
        }
    }
}

// MARK: - Step 5: Sample Size

private extension ExperimentDesignerView {
    var sampleSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepHeader(
                step: 5,
                title: "How many specimens?",
                infoText: "A larger sample size reduces the impact of individual variation. More specimens give you greater statistical power and a more reliable, reproducible result."
            )

            VStack(spacing: 10) {
                Text("\(experimentVM.sampleSize)")
                    .font(.system(size: 48, design: .monospaced).weight(.bold))
                    .foregroundStyle(ColorTheme.textPrimary)
                    .monospacedDigit()

                Slider(
                    value: Binding(
                        get: { Double(experimentVM.sampleSize) },
                        set: { experimentVM.sampleSize = Int($0) }
                    ),
                    in: 5...50,
                    step: 1
                )
                .tint(sampleSizeColor)

                Text(sampleSizeLabel)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(sampleSizeColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(16)
            .background(ColorTheme.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(ColorTheme.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            if isFirstTime {
                Text("Tip: A sample of 25 or more provides solid statistical power.")
                    .font(.system(.caption))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .italic()
            }
        }
    }

    var sampleSizeLabel: String {
        switch experimentVM.sampleSize {
        case 5...9:   return "Very small — results may be unreliable"
        case 10...14: return "Small — expect significant variation"
        case 15...24: return "Moderate — acceptable for exploration"
        case 25...39: return "Good — solid statistical power"
        default:      return "Excellent — highest confidence potential"
        }
    }

    var sampleSizeColor: Color {
        ColorTheme.accent
    }
}

// MARK: - Run Button

private extension ExperimentDesignerView {
    var runButton: some View {
        Button {
            runTapCount += 1
            navigateToRunner = true
        } label: {
            Label("Run Experiment", systemImage: "play.circle")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(experimentVM.canRun ? .white : ColorTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(experimentVM.canRun
                            ? ColorTheme.accent
                            : ColorTheme.cardBackground)
                )
        }
        .disabled(!experimentVM.canRun)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: experimentVM.canRun)
        .sensoryFeedback(.impact(weight: .medium), trigger: runTapCount)
    }
}

// MARK: - Shared Section Header

private extension ExperimentDesignerView {
    func stepHeader(step: Int, title: String, infoText: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("Step \(step)")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(ColorTheme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(ColorTheme.accent.opacity(0.12))
                .clipShape(Capsule())

            Text(title)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(ColorTheme.textPrimary)

            Spacer()

            Button {
                activeInfo = StepInfo(id: step, title: title, text: infoText)
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(ColorTheme.textSecondary)
            }
        }
    }
}

// MARK: - Symbol & Text Helpers

private extension ExperimentDesignerView {
    var ivTip: String {
        switch initialQuestion {
        case .ctmax, .thermalOptimum, .acclimationCapacity, .heatShockResponse:
            return "Tip: In thermal biology, the independent variable is almost always Temperature."
        case .uvResistance:
            return "Tip: This experiment tests UV exposure — try Light Level as your independent variable."
        case .desiccationTolerance:
            return "Tip: This experiment tests water loss — try Exposure Duration (time in dry conditions) or Humidity (water availability) as your independent variable."
        }
    }

    var dvTip: String {
        switch initialQuestion {
        case .ctmax, .acclimationCapacity:
            return "Tip: Survival Rate directly captures the lethal threshold you're looking for."
        case .thermalOptimum:
            return "Tip: Movement Speed or Growth Rate best reflects peak performance."
        case .heatShockResponse:
            return "Tip: Protein Activity directly measures the heat-shock stress response."
        case .uvResistance:
            return "Tip: Survival Rate shows you directly how many specimens withstand the UV dose."
        case .desiccationTolerance:
            return "Tip: Survival Rate shows you directly how many specimens survive drying out."
        }
    }

    func ivSymbol(_ iv: IndependentVariable) -> String {
        switch iv {
        case .temperature:    return "thermometer.medium"
        case .exposureDuration: return "clock"
        case .lightLevel:     return "sun.max"
        case .humidity:       return "drop.fill"
        }
    }

    func dvSymbol(_ dv: DependentVariable) -> String {
        switch dv {
        case .survivalRate:   return "heart.circle"
        case .movementSpeed:  return "hare"
        case .growthRate:     return "chart.line.uptrend.xyaxis"
        case .proteinActivity: return "bolt.circle"
        }
    }

    func cvSymbol(_ cv: ControlledVariable) -> String {
        switch cv {
        case .humidity:       return "drop.fill"
        case .light:          return "sun.max"
        case .food:           return "fork.knife"
        case .specimenAge:    return "clock.badge.checkmark"
        case .samplePrepTime: return "timer"
        }
    }

    func questionPlainText(_ q: ResearchQuestion) -> String {
        switch q {
        case .ctmax:
            return "At what temperature does \(organism.commonName) stop functioning?"
        case .thermalOptimum:
            return "At what temperature does \(organism.commonName) perform its best?"
        case .acclimationCapacity:
            return "Can \(organism.commonName) adapt to warmer conditions over time?"
        case .heatShockResponse:
            return "How does \(organism.commonName) protect itself from sudden heat?"
        case .uvResistance:
            return "How well does \(organism.commonName) survive increasing UV exposure?"
        case .desiccationTolerance:
            return "How well does \(organism.commonName) survive drying conditions?"
        }
    }

    func questionDefinition(_ q: ResearchQuestion) -> String {
        switch q {
        case .ctmax:
            return "CTMax — the temperature at which normal function breaks down irreversibly."
        case .thermalOptimum:
            return "Thermal Optimum — where growth, movement, and metabolic performance peak."
        case .acclimationCapacity:
            return "Acclimation — how much thermal tolerance can shift after gradual exposure."
        case .heatShockResponse:
            return "Heat Shock — protective proteins triggered by dangerously high temperatures."
        case .uvResistance:
            return "UV Resistance — how well the organism survives increasing light exposure doses."
        case .desiccationTolerance:
            return "Desiccation Tolerance — how well the organism survives loss of body water."
        }
    }
}
