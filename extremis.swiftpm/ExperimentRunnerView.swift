import SwiftUI

// MARK: - Specimen Model

struct SpecimenDot: Identifiable {
    let id = UUID()
    let position: CGPoint   // fractional position in [0, 1] × [0, 1] within its group area
    let deathTemp: Double   // temperature at which this specimen fades; .infinity = survives
    let isControl: Bool
    let blinkPhase: Double  // random offset so each dot pulses independently
}

// MARK: - Live Chart (shared with PostExperimentView)

/// Scatter-plot canvas that reveals points progressively as the stimulus value climbs.
struct LiveChartView: View {
    var points: [DataPoint]
    var organism: Organism
    /// Drives the fallback x-axis range and axis label. Defaults to `.ctmax` (thermal range).
    var researchQuestion: ResearchQuestion = .ctmax
    /// Only draw points with x ≤ this value. Pass `.infinity` for a fully-revealed chart.
    var showUpToTemp: Double = .infinity
    /// When set, overrides xMin/xMax with the chosen IV's display range.
    var independentVariable: IndependentVariable? = nil

    private var xMin: Double {
        if let iv = independentVariable, let range = iv.xDisplayRange {
            return range.lowerBound
        }
        return researchQuestion.xDisplayRange?.lowerBound ?? organism.trueThermalRangeMin
    }
    private var xMax: Double {
        if let iv = independentVariable, let range = iv.xDisplayRange {
            return range.upperBound
        }
        return researchQuestion.xDisplayRange?.upperBound ?? (organism.trueThermalRangeMax + 5)
    }

    var body: some View {
        Canvas { ctx, size in
            let m: CGFloat = 8
            let cw = size.width - m * 2
            let ch = size.height - m * 2
            let xRange = xMax - xMin

            // Subtle horizontal grid at 25 / 50 / 75 %
            for frac in [0.25, 0.5, 0.75] as [Double] {
                let y = m + CGFloat(1.0 - frac) * ch
                var p = Path()
                p.move(to: CGPoint(x: m, y: y))
                p.addLine(to: CGPoint(x: size.width - m, y: y))
                ctx.stroke(p, with: .color(ColorTheme.border.opacity(0.5)), lineWidth: 1)
            }

            let visible = points.filter { $0.x <= showUpToTemp }.sorted { $0.x < $1.x }

            // Faint trend line connecting visible points
            if visible.count >= 2 {
                var line = Path()
                for (i, pt) in visible.enumerated() {
                    let px = m + CGFloat((pt.x - xMin) / xRange) * cw
                    let py = m + CGFloat(1.0 - pt.y) * ch
                    i == 0 ? line.move(to: CGPoint(x: px, y: py))
                           : line.addLine(to: CGPoint(x: px, y: py))
                }
                ctx.stroke(line, with: .color(ColorTheme.border), lineWidth: 1.5)
            }

            // Scatter dots in accent color
            for pt in visible {
                let px = m + CGFloat((pt.x - xMin) / xRange) * cw
                let py = m + CGFloat(1.0 - pt.y) * ch
                let r: CGFloat = 5.0
                ctx.fill(
                    Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                    with: .color(ColorTheme.accent.opacity(0.85))
                )
            }
        }
    }
}

// MARK: - Experiment Runner

/// 12-second animated experiment sequence: setup → temperature ramp → complete.
struct ExperimentRunnerView: View {
    var experimentVM: ExperimentViewModel
    var indexViewModel: IndexViewModel

    @State private var specimens: [SpecimenDot] = []
    @State private var startDate: Date? = nil
    @State private var currentPhase: RunnerPhase = .setup
    @State private var navigateToPost = false
    @State private var tryAgainRequested = false
    @State private var animationTask: Task<Void, Never>? = nil
    @Environment(\.dismiss) private var dismiss

    enum RunnerPhase { case setup, experiment, complete, done }

    private var organism: Organism { experimentVM.selectedOrganism }

    private var researchQuestion: ResearchQuestion { experimentVM.researchQuestion }

    // Chart height constant — used by both chartSection and the y-axis tick layout.
    private let chartH: CGFloat = 250

    var body: some View {
        ZStack {
            ColorTheme.background.ignoresSafeArea()
            mainStack
        }
        .navigationTitle(organism.commonName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(currentPhase != .done)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if currentPhase != .done {
                    Button("Skip") { handleSkip() }
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToPost) {
            if let result = experimentVM.latestResult {
                PostExperimentView(
                    result: result,
                    organism: organism,
                    experimentVM: experimentVM,
                    indexViewModel: indexViewModel,
                    onTryAgain: { tryAgainRequested = true }
                )
            }
        }
        .onChange(of: tryAgainRequested) { _, v in
            if v { experimentVM.reset(); dismiss() }
        }
        .onAppear {
            experimentVM.prepareResult()
            if let result = experimentVM.latestResult { setupSpecimens(from: result) }
        }
        .task {
            startDate = Date()
            animationTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled else { return }
                currentPhase = .experiment

                try? await Task.sleep(nanoseconds: 8_000_000_000)
                guard !Task.isCancelled else { return }
                currentPhase = .complete

                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled else { return }
                currentPhase = .done
                navigateToPost = true
            }
            await animationTask?.value
        }
        .onDisappear { animationTask?.cancel() }
    }

    // MARK: - Main stack

    @ViewBuilder
    private var mainStack: some View {
        if let start = startDate {
            TimelineView(.animation(paused: currentPhase == .done)) { ctx in
                let elapsed = ctx.date.timeIntervalSince(start)
                let temp = currentStimulusValue(elapsed: elapsed)
                VStack(spacing: 0) {
                    // Dots — fills all space not claimed by temperature + graph
                    specimenArea(elapsed: elapsed, temp: temp)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 8)

                    // Stimulus value or setup/complete status — sits just above the graph
                    if currentPhase == .experiment || currentPhase == .complete || currentPhase == .done {
                        stimulusDisplay(value: temp)
                    } else {
                        Text("\(min(experimentVM.sampleSize, 50)) specimens ready")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(ColorTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                    }

                    // Graph — immediately below temperature, tab bar clearance at bottom
                    chartSection(temp: temp)
                        .padding(.bottom, 100)
                }
            }
        }
    }

    // MARK: - Live stimulus display (centered in the gap)

    private func stimulusDisplay(value: Double) -> some View {
        let iv = experimentVM.independentVariable
        // Integer format for large-unit values (UV dose, humidity); decimal for time/temperature
        let fmt: String
        if iv == .lightLevel || iv == .humidity {
            fmt = String(format: "%.0f", value)
        } else {
            fmt = String(format: "%.1f", value)
        }
        let unit = iv?.stimulusUnit ?? researchQuestion.stimulusUnit
        return HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(fmt)
                .font(.system(size: 56, design: .monospaced).weight(.bold))
                .foregroundStyle(ColorTheme.textPrimary)
                .contentTransition(.numericText(countsDown: false))
            Text(unit)
                .font(.system(.title2, design: .monospaced, weight: .regular))
                .foregroundStyle(ColorTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 10)
    }

    // MARK: - Specimen canvas

    private func specimenArea(elapsed: TimeInterval, temp: Double) -> some View {
        GeometryReader { geo in
            let hasControl = experimentVM.hasControlGroup
            let pad: CGFloat = 16
            let labelH: CGFloat = hasControl ? 26 : 0

            Canvas { ctx, size in
                for dot in specimens {
                    let base = dotOpacity(dot: dot, temp: temp)
                    guard base > 0 else { continue }

                    // Per-dot independent blink: oscillates 0.60–0.90 when alive
                    let isAlive = base > 0.3
                    let displayOpacity: Double
                    if isAlive {
                        displayOpacity = 0.60 + 0.30 * (0.5 + 0.5 * sin(elapsed * 2.2 + dot.blinkPhase))
                    } else {
                        displayOpacity = base  // dying: raw fade, no blink
                    }

                    // Map fractional [0,1] position into the group's screen area
                    let availW: CGFloat
                    let originX: CGFloat
                    if dot.isControl {
                        availW  = size.width * 0.5 - pad * 2
                        originX = pad
                    } else if hasControl {
                        availW  = size.width * 0.5 - pad * 2
                        originX = size.width * 0.5 + pad
                    } else {
                        availW  = size.width - pad * 2
                        originX = pad
                    }
                    let availH = size.height - labelH - pad
                    let px = originX + dot.position.x * availW
                    let py = labelH  + dot.position.y * availH

                    let r: CGFloat = 7.0
                    let rect = CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)
                    let dotColor = dot.isControl
                        ? ColorTheme.textSecondary.opacity(displayOpacity * 0.7)
                        : ColorTheme.accent.opacity(displayOpacity)
                    ctx.fill(Path(ellipseIn: rect), with: .color(dotColor))
                }
            }

            // Group labels at top of each half
            if hasControl {
                let size = geo.size
                groupLabel("Control", at: CGPoint(x: size.width * 0.25, y: 13))
                groupLabel("Test",    at: CGPoint(x: size.width * 0.75, y: 13))
            }
        }
    }

    private func groupLabel(_ text: String, at point: CGPoint) -> some View {
        Text(text)
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundStyle(ColorTheme.textSecondary.opacity(0.7))
            .position(x: point.x, y: point.y)
    }

    // MARK: - Chart section with labeled axes

    private func chartSection(temp: Double) -> some View {
        // Axis geometry — must match LiveChartView's internal margin (m = 8)
        let m: CGFloat = 8
        let plotH = chartH - m * 2          // usable plot height
        let tickInterval = plotH / 4        // gap between each of the 5 y-ticks

        // Use chosen IV's range when available; fall back to research question / organism range
        let iv = experimentVM.independentVariable
        let xMin = iv?.xDisplayRange?.lowerBound
            ?? researchQuestion.xDisplayRange?.lowerBound
            ?? organism.trueThermalRangeMin
        let xMax = iv?.xDisplayRange?.upperBound
            ?? researchQuestion.xDisplayRange?.upperBound
            ?? (organism.trueThermalRangeMax + 5)
        let xRange = xMax - xMin
        let xStep: Double = xRange > 600 ? 200 : (xRange > 200 ? 100 : (xRange > 60 ? 20 : (xRange > 40 ? 15 : (xRange > 20 ? 10 : 5))))
        let xTicks = Array(stride(from: ceil(xMin / xStep) * xStep, through: xMax, by: xStep))
        let dv = experimentVM.dependentVariable ?? .survivalRate
        let yAxisTicks = dv.yAxisTicks

        // Dynamic chart title: informative name when IV is valid, neutral "[DV] vs. [IV]" otherwise
        let chartTitle: String
        if let iv, researchQuestion.ivCredit(for: iv) == 2 {
            chartTitle = researchQuestion.chartTitle
        } else if let iv, let dv = experimentVM.dependentVariable {
            chartTitle = "\(dv.displayName) vs. \(iv.displayName)"
        } else {
            chartTitle = researchQuestion.chartTitle
        }

        // X-axis label follows the chosen IV
        let xAxisLabel = iv?.axisLabel ?? researchQuestion.xAxisLabel

        return VStack(alignment: .leading, spacing: 6) {
            // ── Chart title ───────────────────────────────────────────────
            Text(chartTitle)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(ColorTheme.textPrimary)
                .padding(.horizontal, 16)

            // ── Axes + chart body ─────────────────────────────────────────
            HStack(alignment: .top, spacing: 0) {

                // Rotated y-axis label (DV name, reads bottom-to-top)
                Text(dv.displayName)
                    .font(.system(size: 8, design: .rounded))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .lineLimit(1)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
                    .frame(width: 12, height: chartH)

                // Y-axis tick labels — scale and unit follow the chosen DV
                VStack(spacing: 0) {
                    Spacer().frame(height: max(0, m - 7)) // align first label to top grid line
                    ForEach(yAxisTicks.indices, id: \.self) { idx in
                        Text(yAxisTicks[idx])
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(ColorTheme.textSecondary)
                            .frame(height: 14)
                        if idx < yAxisTicks.count - 1 {
                            Spacer().frame(height: max(0, tickInterval - 14))
                        }
                    }
                    Spacer()
                }
                .frame(width: 36, height: chartH)

                // Chart canvas + x-axis labels below
                VStack(spacing: 4) {
                    // Chart canvas with n= badge
                    ZStack(alignment: .topTrailing) {
                        if let result = experimentVM.latestResult {
                            LiveChartView(
                                points: result.rawDataPoints,
                                organism: organism,
                                researchQuestion: researchQuestion,
                                showUpToTemp: temp,
                                independentVariable: iv
                            )
                            .background(ColorTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        Text("n = \(experimentVM.sampleSize)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(ColorTheme.textSecondary)
                            .padding(.trailing, 8)
                            .padding(.top, 5)
                    }
                    .frame(height: chartH)

                    // X-axis tick values — positioned to match chart x-coordinate mapping
                    GeometryReader { geo in
                        let usableW = geo.size.width - m * 2
                        ZStack {
                            ForEach(xTicks, id: \.self) { t in
                                let frac = CGFloat((t - xMin) / xRange)
                                Text("\(Int(t))")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(ColorTheme.textSecondary)
                                    .position(x: m + frac * usableW, y: 7)
                            }
                        }
                    }
                    .frame(height: 14)

                    // X-axis label — follows the chosen IV
                    Text(xAxisLabel)
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(ColorTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityLabel(xAxisLabel)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Skip

    private func handleSkip() {
        animationTask?.cancel()
        currentPhase = .done
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            navigateToPost = true
        }
    }
}

// MARK: - Physics Helpers

private extension ExperimentRunnerView {
    func currentStimulusValue(elapsed: TimeInterval) -> Double {
        let iv = experimentVM.independentVariable
        let lo: Double
        let hi: Double
        if let range = iv?.xDisplayRange {
            lo = range.lowerBound; hi = range.upperBound
        } else {
            // Temperature (nil xDisplayRange) → use organism-specific thermal sweep
            let r = researchQuestion.stimulusRange(organism: organism)
            lo = r.lo; hi = r.hi
        }
        let phase2Elapsed = max(0, min(elapsed - 2.0, 8.0))
        return lo + (phase2Elapsed / 8.0) * (hi - lo)
    }

    func dotOpacity(dot: SpecimenDot, temp: Double) -> Double {
        guard !dot.isControl else { return 0.75 }
        if dot.deathTemp == .infinity { return 0.90 }
        if temp < dot.deathTemp { return 0.90 }
        let fade = min(1.0, (temp - dot.deathTemp) / 1.5)
        return max(0, 0.90 * (1.0 - fade))
    }

    func setupSpecimens(from result: ExperimentResult) {
        let n = min(experimentVM.sampleSize, 50)
        let sorted = result.rawDataPoints.sorted { $0.x < $1.x }
        var dots: [SpecimenDot] = []

        for i in 0..<n {
            let pt = sorted[i % sorted.count]
            dots.append(SpecimenDot(
                position: CGPoint(x: Double.random(in: 0...1), y: Double.random(in: 0...1)),
                deathTemp: pt.y < 0.5 ? pt.x : Double.infinity,
                isControl: false,
                blinkPhase: Double.random(in: 0 ..< (.pi * 2))
            ))
        }

        if experimentVM.hasControlGroup {
            for _ in 0..<n {
                dots.append(SpecimenDot(
                    position: CGPoint(x: Double.random(in: 0...1), y: Double.random(in: 0...1)),
                    deathTemp: .infinity,
                    isControl: true,
                    blinkPhase: Double.random(in: 0 ..< (.pi * 2))
                ))
            }
        }

        specimens = dots
    }

}
