import Foundation

/// Pure-logic engine that scores experiments, generates results, and checks unlocks.
/// All functions are static with no side effects.
struct ExperimentEngine {

    // MARK: - Gaussian Helper (Box-Muller)

    /// Returns a random sample from a normal distribution with mean 0 and standard deviation `sigma`.
    private static func gaussianRandom(sigma: Double) -> Double {
        let u1 = Double.random(in: 0.001...1.0)
        let u2 = Double.random(in: 0.0...1.0)
        let z = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        return z * sigma
    }

    // MARK: - 1. Confidence Scoring

    /// Calculate confidence score (0–10 raw) and return star rating (1–5).
    static func calculateConfidence(experiment: Experiment, organism: Organism) -> Int {
        var score: Double = 0

        // Correct IV (+2): some questions accept more than one valid IV
        score += Double(experiment.researchQuestion.ivCredit(for: experiment.independentVariable))

        // Correct DV (+2 full, +1 partial)
        score += dvScore(question: experiment.researchQuestion, dv: experiment.dependentVariable)

        // Control group (+2)
        if experiment.hasControlGroup {
            score += 2
        }

        // Controlled variables (up to +2)
        var controlledScore: Double = 0
        for cv in experiment.controlledVariables {
            switch cv {
            case .humidity:
                if organism.sensitiveToHumidity { controlledScore += 0.5 }
            case .light:
                if organism.sensitiveToLight { controlledScore += 0.5 }
            case .food:
                if organism.sensitiveToFood { controlledScore += 0.5 }
            case .specimenAge:
                if organism.sensitiveToAge { controlledScore += 0.5 }
            case .samplePrepTime:
                controlledScore += 0.25
            }
        }
        score += min(controlledScore, 2.0)

        // Sample size (up to +2)
        let n = experiment.sampleSize
        if n >= 40 {
            score += 2
        } else if n >= 25 {
            score += 1.5
        } else if n >= 15 {
            score += 1
        } else if n >= 10 {
            score += 0.5
        }

        return starRating(from: Int(score.rounded(.down)))
    }

    /// Map DV choice to credit for a given research question.
    private static func dvScore(question: ResearchQuestion, dv: DependentVariable) -> Double {
        switch question {
        case .ctmax:
            switch dv {
            case .survivalRate: return 2
            case .movementSpeed: return 1
            default: return 0
            }
        case .thermalOptimum:
            switch dv {
            case .movementSpeed: return 2
            case .growthRate: return 2
            default: return 0
            }
        case .acclimationCapacity:
            switch dv {
            case .survivalRate: return 2
            default: return 0
            }
        case .heatShockResponse:
            switch dv {
            case .proteinActivity: return 2
            case .survivalRate: return 1
            default: return 0
            }
        case .uvResistance:
            switch dv {
            case .survivalRate: return 2
            case .movementSpeed: return 1
            default: return 0
            }
        case .desiccationTolerance:
            switch dv {
            case .survivalRate: return 2
            default: return 0
            }
        }
    }

    /// Convert raw 0–10 score to 1–5 stars.
    private static func starRating(from score: Int) -> Int {
        switch score {
        case 9...10: return 5
        case 7...8: return 4
        case 5...6: return 3
        case 3...4: return 2
        default: return 1
        }
    }

    // MARK: - 2. Result Generation

    /// Generate a full experiment result including measured value, data points, and feedback.
    static func generateResult(experiment: Experiment, organism: Organism) -> ExperimentResult {
        let confidence = calculateConfidence(experiment: experiment, organism: organism)

        // True value for the research question
        let trueValue = trueValueFor(question: experiment.researchQuestion, organism: organism)

        // Base noise σ by confidence
        var sigma = noiseSigma(for: confidence)

        // For 0–1 scale values (acclimation, heatShock, uvResistance, desiccation), scale sigma down
        let isScaled = experiment.researchQuestion == .acclimationCapacity
            || experiment.researchQuestion == .heatShockResponse
            || experiment.researchQuestion == .uvResistance
            || experiment.researchQuestion == .desiccationTolerance
        if isScaled {
            sigma /= 20.0
        }

        var measuredValue: Double
        var effectiveConfidence = confidence

        let dvCredit = dvScore(question: experiment.researchQuestion, dv: experiment.dependentVariable)

        if experiment.researchQuestion.ivCredit(for: experiment.independentVariable) == 0 {
            // Wrong IV: random value in wide range, confidence capped at 1
            let range = isScaled ? 0.5 : 20.0
            measuredValue = trueValue + Double.random(in: -range...range)
            effectiveConfidence = 1
        } else if dvCredit == 0 {
            // Fully wrong DV: systematic bias of ±8°C
            let bias = (isScaled ? 8.0 / 20.0 : 8.0) * (Bool.random() ? 1.0 : -1.0)
            measuredValue = trueValue + gaussianRandom(sigma: sigma) + bias
        } else if dvCredit == 1 {
            // Partially correct DV: systematic bias of ±3°C
            let bias = (isScaled ? 3.0 / 20.0 : 3.0) * (Bool.random() ? 1.0 : -1.0)
            measuredValue = trueValue + gaussianRandom(sigma: sigma) + bias
        } else {
            // Correct DV: only noise
            measuredValue = trueValue + gaussianRandom(sigma: sigma)
        }

        // Clamp 0–1 scale values
        if isScaled {
            measuredValue = max(0, min(1, measuredValue))
        }

        let errorMargin = sigma * 1.96

        let dataPoints = generateDataPoints(
            experiment: experiment,
            organism: organism,
            confidence: effectiveConfidence
        )
        let feedback = generateFeedback(
            experiment: experiment,
            organism: organism
        )

        let isRelevant = experiment.researchQuestion.ivCredit(for: experiment.independentVariable) == 2
            && dvScore(question: experiment.researchQuestion, dv: experiment.dependentVariable) >= 2

        return ExperimentResult(
            experimentId: experiment.id,
            researchQuestion: experiment.researchQuestion,
            independentVariable: experiment.independentVariable,
            dependentVariable: experiment.dependentVariable,
            isRelevantCombination: isRelevant,
            measuredValue: measuredValue,
            confidenceRating: effectiveConfidence,
            errorMargin: errorMargin,
            feedbackItems: feedback,
            rawDataPoints: dataPoints
        )
    }

    /// Look up the true hidden value for a research question.
    private static func trueValueFor(question: ResearchQuestion, organism: Organism) -> Double {
        switch question {
        case .ctmax: return organism.trueCTMax
        case .thermalOptimum: return organism.trueThermalOptimum
        case .acclimationCapacity: return organism.trueAcclimationCapacity
        case .heatShockResponse: return organism.trueHeatShockResponse
        case .uvResistance: return organism.trueUVResistance
        case .desiccationTolerance: return organism.trueDesiccationTolerance
        }
    }

    /// Noise standard deviation by star rating.
    private static func noiseSigma(for stars: Int) -> Double {
        switch stars {
        case 5: return 0.3
        case 4: return 1.0
        case 3: return 2.5
        case 2: return 5.0
        default: return 10.0
        }
    }

    // MARK: - 3. Data Point Generation

    /// Generate simulated raw data points for visualization.
    static func generateDataPoints(
        experiment: Experiment,
        organism: Organism,
        confidence: Int
    ) -> [DataPoint] {
        let n = experiment.sampleSize

        // Wrong IV → flat scatter across the CHOSEN IV's x-range (not the question's range).
        // The flat y-values (0.2–0.8) make it visually clear there is no pattern.
        guard experiment.researchQuestion.ivCredit(for: experiment.independentVariable) == 2 else {
            let xRange = experiment.independentVariable.xDisplayRange
                ?? (organism.trueThermalRangeMin...organism.trueThermalRangeMax)
            return (0..<n).map { _ in
                DataPoint(x: Double.random(in: xRange), y: Double.random(in: 0.2...0.8))
            }
        }

        // Per-point noise scale by confidence
        let pointNoise = pointNoiseScale(for: confidence)

        // Count uncontrolled sensitive variables for confounding shifts
        let uncontrolledSensitive = countUncontrolledSensitive(experiment: experiment, organism: organism)

        switch experiment.researchQuestion {
        case .ctmax:
            return generateSurvivalCurve(
                n: n,
                organism: organism,
                threshold: organism.trueCTMax,
                pointNoise: pointNoise,
                uncontrolledCount: uncontrolledSensitive
            )

        case .thermalOptimum:
            return generateBellCurve(
                n: n,
                organism: organism,
                optimum: organism.trueThermalOptimum,
                pointNoise: pointNoise,
                uncontrolledCount: uncontrolledSensitive
            )

        case .acclimationCapacity:
            return generateSurvivalCurve(
                n: n,
                organism: organism,
                threshold: organism.trueCTMax * (1.0 + organism.trueAcclimationCapacity * 0.1),
                pointNoise: pointNoise,
                uncontrolledCount: uncontrolledSensitive
            )

        case .heatShockResponse:
            return generateStepFunction(
                n: n,
                organism: organism,
                activationTemp: organism.trueThermalOptimum
                    + (organism.trueCTMax - organism.trueThermalOptimum) * 0.5,
                maxResponse: organism.trueHeatShockResponse,
                pointNoise: pointNoise,
                uncontrolledCount: uncontrolledSensitive
            )

        case .uvResistance:
            // Sigmoid decay: survival falls as UV dose (J/m²) rises past organism's LD50.
            return generateUVDecayCurve(
                n: n,
                ld50: organism.uvLD50,
                steepness: organism.uvSteepness,
                pointNoise: pointNoise,
                uncontrolledCount: uncontrolledSensitive
            )

        case .desiccationTolerance:
            if experiment.independentVariable == .humidity {
                // Ascending sigmoid: survival rises as relative humidity increases.
                return generateHumidityDesiccationCurve(
                    n: n,
                    organism: organism,
                    pointNoise: pointNoise,
                    uncontrolledCount: uncontrolledSensitive
                )
            } else {
                // Exponential decay with lag + plateau: survival holds, then falls, then floors.
                return generateDesiccationCurve(
                    n: n,
                    lag: organism.desiccationLag,
                    decayRate: organism.desiccationDecayRate,
                    baseline: organism.desiccationBaseline,
                    pointNoise: pointNoise,
                    uncontrolledCount: uncontrolledSensitive
                )
            }
        }
    }

    /// Noise scale per data point by confidence.
    private static func pointNoiseScale(for stars: Int) -> Double {
        switch stars {
        case 5: return 0.03
        case 4: return 0.05
        case 3: return 0.08
        case 2: return 0.12
        default: return 0.15
        }
    }

    /// Count sensitive variables the experimenter left uncontrolled.
    private static func countUncontrolledSensitive(experiment: Experiment, organism: Organism) -> Int {
        var count = 0
        if organism.sensitiveToHumidity && !experiment.controlledVariables.contains(.humidity) { count += 1 }
        if organism.sensitiveToLight && !experiment.controlledVariables.contains(.light) { count += 1 }
        if organism.sensitiveToFood && !experiment.controlledVariables.contains(.food) { count += 1 }
        if organism.sensitiveToAge && !experiment.controlledVariables.contains(.specimenAge) { count += 1 }
        return count
    }

    /// Sigmoid survival curve: high survival below threshold, drops off above.
    private static func generateSurvivalCurve(
        n: Int,
        organism: Organism,
        threshold: Double,
        pointNoise: Double,
        uncontrolledCount: Int
    ) -> [DataPoint] {
        let tempMin = organism.trueThermalRangeMin
        let tempMax = organism.trueThermalRangeMax + 5.0
        return (0..<n).map { i in
            let temp = tempMin + (tempMax - tempMin) * Double(i) / Double(max(n - 1, 1))
            var survival = 1.0 / (1.0 + exp(1.0 * (temp - threshold)))
            // Confounding: shift subgroups to simulate uncontrolled variable effects
            if uncontrolledCount > 0 && i % 3 == 0 {
                survival += Double(uncontrolledCount) * 0.08 * (Bool.random() ? 1 : -1)
            }
            survival += gaussianRandom(sigma: pointNoise)
            return DataPoint(x: temp, y: max(0, min(1, survival)))
        }
    }

    /// Bell-shaped performance curve peaking at the thermal optimum.
    private static func generateBellCurve(
        n: Int,
        organism: Organism,
        optimum: Double,
        pointNoise: Double,
        uncontrolledCount: Int
    ) -> [DataPoint] {
        let tempMin = organism.trueThermalRangeMin
        let tempMax = organism.trueThermalRangeMax + 5.0
        let spread = (organism.trueThermalRangeMax - organism.trueThermalRangeMin) / 3.0
        return (0..<n).map { i in
            let temp = tempMin + (tempMax - tempMin) * Double(i) / Double(max(n - 1, 1))
            let diff = temp - optimum
            var performance = exp(-(diff * diff) / (2.0 * spread * spread))
            if uncontrolledCount > 0 && i % 3 == 0 {
                performance += Double(uncontrolledCount) * 0.06 * (Bool.random() ? 1 : -1)
            }
            performance += gaussianRandom(sigma: pointNoise)
            return DataPoint(x: temp, y: max(0, min(1, performance)))
        }
    }

    /// Step function: low response below activation temperature, sharp rise above.
    private static func generateStepFunction(
        n: Int,
        organism: Organism,
        activationTemp: Double,
        maxResponse: Double,
        pointNoise: Double,
        uncontrolledCount: Int
    ) -> [DataPoint] {
        let tempMin = organism.trueThermalRangeMin
        let tempMax = organism.trueThermalRangeMax + 5.0
        return (0..<n).map { i in
            let temp = tempMin + (tempMax - tempMin) * Double(i) / Double(max(n - 1, 1))
            // Steep sigmoid for step-like transition
            var response = maxResponse / (1.0 + exp(-0.8 * (temp - activationTemp)))
            if uncontrolledCount > 0 && i % 3 == 0 {
                response += Double(uncontrolledCount) * 0.05 * (Bool.random() ? 1 : -1)
            }
            response += gaussianRandom(sigma: pointNoise)
            return DataPoint(x: temp, y: max(0, min(1, response)))
        }
    }

    /// UV dose-response: sigmoid decay from 100% survival at low dose to 0% at high dose.
    /// x-axis spans 0–1000 J/m². LD50 is the dose at which 50% survive.
    private static func generateUVDecayCurve(
        n: Int,
        ld50: Double,
        steepness: Double,
        pointNoise: Double,
        uncontrolledCount: Int
    ) -> [DataPoint] {
        let xMin = 0.0, xMax = 1000.0
        return (0..<n).map { i in
            let dose = xMin + (xMax - xMin) * Double(i) / Double(max(n - 1, 1))
            var survival = 1.0 / (1.0 + exp(steepness * (dose - ld50)))
            if uncontrolledCount > 0 && i % 3 == 0 {
                survival += Double(uncontrolledCount) * 0.06 * (Bool.random() ? 1 : -1)
            }
            survival += gaussianRandom(sigma: pointNoise)
            return DataPoint(x: dose, y: max(0, min(1, survival)))
        }
    }

    /// Desiccation survival: high survival through the lag period, then exponential decay
    /// to a species-specific baseline (0 for intolerant; >0 for anhydrobiosis-capable organisms).
    /// x-axis spans 0–168 hours (1 week).
    private static func generateDesiccationCurve(
        n: Int,
        lag: Double,
        decayRate: Double,
        baseline: Double,
        pointNoise: Double,
        uncontrolledCount: Int
    ) -> [DataPoint] {
        let xMin = 0.0, xMax = 168.0
        return (0..<n).map { i in
            let time = xMin + (xMax - xMin) * Double(i) / Double(max(n - 1, 1))
            let elapsed = max(0.0, time - lag)
            var survival = (1.0 - baseline) * exp(-decayRate * elapsed) + baseline
            if uncontrolledCount > 0 && i % 3 == 0 {
                survival += Double(uncontrolledCount) * 0.06 * (Bool.random() ? 1 : -1)
            }
            survival += gaussianRandom(sigma: pointNoise)
            return DataPoint(x: time, y: max(0, min(1, survival)))
        }
    }

    /// Humidity–desiccation survival: ascending sigmoid over 0–100% relative humidity.
    /// At low humidity the organism desiccates quickly (low survival);
    /// at high humidity it retains body water and thrives.
    private static func generateHumidityDesiccationCurve(
        n: Int,
        organism: Organism,
        pointNoise: Double,
        uncontrolledCount: Int
    ) -> [DataPoint] {
        let halfPoint = (1.0 - organism.trueDesiccationTolerance) * 100.0
        let steepness = 0.08
        let baseline = organism.desiccationBaseline
        return (0..<n).map { i in
            let humidity = 100.0 * Double(i) / Double(max(n - 1, 1))
            var survival = baseline + (1.0 - baseline) / (1.0 + exp(-steepness * (humidity - halfPoint)))
            if uncontrolledCount > 0 && i % 3 == 0 {
                survival += Double(uncontrolledCount) * 0.05 * (Bool.random() ? 1 : -1)
            }
            survival += gaussianRandom(sigma: pointNoise)
            return DataPoint(x: humidity, y: max(0, min(1, survival)))
        }
    }

    // MARK: - 4. Feedback Generation

    /// Generate up to 4 educational feedback items (≤2 positive, ≤2 improvement).
    /// Actionable advice is merged directly into each improvement message.
    static func generateFeedback(experiment: Experiment, organism: Organism) -> [FeedbackItem] {
        var positives: [FeedbackItem] = []
        var improvements: [FeedbackItem] = []

        // IV — use ivCredit so all valid IVs (e.g. humidity for desiccation) get positive feedback
        if experiment.researchQuestion.ivCredit(for: experiment.independentVariable) == 2 {
            positives.append(FeedbackItem(
                message: "\(experiment.independentVariable.displayName) is the right variable to manipulate for \(experiment.researchQuestion.displayName.lowercased()).",
                isPositive: true
            ))
        } else {
            improvements.append(FeedbackItem(
                message: ivImprovementMessage(experiment: experiment),
                isPositive: false
            ))
        }

        // DV
        let dvCredit = dvScore(question: experiment.researchQuestion, dv: experiment.dependentVariable)
        if dvCredit == 2 {
            positives.append(FeedbackItem(
                message: "\(experiment.dependentVariable.displayName) is an ideal measurement for \(experiment.researchQuestion.displayName.lowercased()).",
                isPositive: true
            ))
        } else {
            improvements.append(FeedbackItem(
                message: dvImprovementMessage(experiment: experiment),
                isPositive: false
            ))
        }

        // Control group
        if experiment.hasControlGroup {
            positives.append(FeedbackItem(
                message: "Your control group at baseline temperature gives your results a solid reference point.",
                isPositive: true
            ))
        } else {
            improvements.append(FeedbackItem(
                message: "Without a baseline control group, you can't confirm the effect is due to your independent variable — try toggling it on next time.",
                isPositive: false
            ))
        }

        // Controlled variables
        let missing = firstMissingSensitiveVariable(experiment: experiment, organism: organism)
        let controlled = firstControlledSensitiveVariable(experiment: experiment, organism: organism)
        if let missing {
            improvements.append(FeedbackItem(
                message: "This organism is sensitive to \(missing.displayName.lowercased()) — try controlling for it next time to reduce noise.",
                isPositive: false
            ))
        } else if let controlled {
            positives.append(FeedbackItem(
                message: "Controlling for \(controlled.displayName.lowercased()) eliminates a key source of noise for this organism.",
                isPositive: true
            ))
        }

        // Sample size
        if experiment.sampleSize >= 30 {
            positives.append(FeedbackItem(
                message: "A sample of \(experiment.sampleSize) provides strong statistical power.",
                isPositive: true
            ))
        } else {
            improvements.append(FeedbackItem(
                message: "With only \(experiment.sampleSize) specimens, individual variation could skew your results — try increasing to at least 25 for more reliable data.",
                isPositive: false
            ))
        }

        // Cap: at most 2 positives + 2 improvements = max 4 items total
        return Array(positives.prefix(2)) + Array(improvements.prefix(2))
    }

    /// Improvement message for a wrong IV choice, with actionable advice merged in.
    private static func ivImprovementMessage(experiment: Experiment) -> String {
        let iv = experiment.independentVariable.displayName.lowercased()
        switch experiment.researchQuestion {
        case .ctmax, .thermalOptimum, .acclimationCapacity, .heatShockResponse:
            return "Changing \(iv) doesn't directly test \(experiment.researchQuestion.displayName.lowercased()) — temperature is the variable that drives heat-related responses."
        case .uvResistance:
            return "Changing \(iv) doesn't directly test UV resistance — try Light Level to see how UV exposure affects survival."
        case .desiccationTolerance:
            return "Changing \(iv) doesn't directly test desiccation tolerance — try Exposure Duration (how long organisms survive in dry conditions) or Humidity (how survival varies with water availability)."
        }
    }

    /// Improvement message for a wrong or partial DV choice, with actionable advice merged in.
    private static func dvImprovementMessage(experiment: Experiment) -> String {
        let dv = experiment.dependentVariable.displayName
        let partial = dvScore(question: experiment.researchQuestion, dv: experiment.dependentVariable) == 1
        switch experiment.researchQuestion {
        case .ctmax:
            return partial
                ? "\(dv) gives a partial signal, but Survival Rate directly shows the lethal threshold — the most precise measure for CTMax."
                : "\(dv) doesn't capture the lethal threshold — Survival Rate directly shows when organisms stop surviving."
        case .thermalOptimum:
            return "\(dv) isn't the most direct measure for thermal optimum — Movement Speed or Growth Rate peaks at the optimum temperature."
        case .acclimationCapacity:
            return "\(dv) doesn't directly capture acclimation — Survival Rate shows how well the organism adjusts to new temperatures."
        case .heatShockResponse:
            return partial
                ? "\(dv) gives a signal, but Protein Activity directly measures the heat-shock stress response."
                : "\(dv) doesn't capture the heat-shock response — Protein Activity is the most direct measure."
        case .uvResistance:
            return "\(dv) isn't the most direct measure for UV resistance — Survival Rate shows how many specimens survive increasing UV doses."
        case .desiccationTolerance:
            return "\(dv) doesn't directly capture desiccation tolerance — Survival Rate shows how many specimens survive as conditions get drier."
        }
    }

    /// Find the first sensitive variable the experimenter forgot to control.
    private static func firstMissingSensitiveVariable(
        experiment: Experiment,
        organism: Organism
    ) -> ControlledVariable? {
        if organism.sensitiveToHumidity && !experiment.controlledVariables.contains(.humidity) { return .humidity }
        if organism.sensitiveToLight && !experiment.controlledVariables.contains(.light) { return .light }
        if organism.sensitiveToFood && !experiment.controlledVariables.contains(.food) { return .food }
        if organism.sensitiveToAge && !experiment.controlledVariables.contains(.specimenAge) { return .specimenAge }
        return nil
    }

    /// Find the first sensitive variable the experimenter correctly controlled.
    private static func firstControlledSensitiveVariable(
        experiment: Experiment,
        organism: Organism
    ) -> ControlledVariable? {
        if organism.sensitiveToHumidity && experiment.controlledVariables.contains(.humidity) { return .humidity }
        if organism.sensitiveToLight && experiment.controlledVariables.contains(.light) { return .light }
        if organism.sensitiveToFood && experiment.controlledVariables.contains(.food) { return .food }
        if organism.sensitiveToAge && experiment.controlledVariables.contains(.specimenAge) { return .specimenAge }
        return nil
    }

    // MARK: - 5. Unlock Checking

    /// Check which locked organisms should now be unlockable based on game state.
    static func checkOrganismUnlocks(gameState: GameState, allOrganisms: [Organism]) -> [Organism] {
        var newlyUnlockable: [Organism] = []

        for organism in allOrganisms {
            guard !gameState.unlockedOrganismIds.contains(organism.id) else { continue }

            let shouldUnlock: Bool

            switch organism.commonName {
            case "Reef Coral":
                shouldUnlock = gameState.thermalProfiles.values.contains { $0.completionPercentage == 1.0 }

            case "Desert Beetle":
                shouldUnlock = gameState.highestConfidenceAchieved >= 4

            case "Antarctic Icefish":
                shouldUnlock = gameState.totalExperimentsRun >= 10

            case "Tardigrade":
                shouldUnlock = gameState.highestConfidenceAchieved >= 5

            case "Pompeii Worm":
                let completedCount = gameState.thermalProfiles.values
                    .filter { $0.completionPercentage == 1.0 }.count
                shouldUnlock = completedCount >= 3

            case "Saharan Silver Ant":
                // Requires discovering a CTMax above 50 °C (mirrors "extremophile_hunter" challenge).
                shouldUnlock = gameState.thermalProfiles.values.contains { ($0.discoveredCTMax ?? 0) > 50 }

            case "Wood Frog":
                let icefishId = UUID(uuidString: "00000001-0001-0001-0001-000000000006")!
                shouldUnlock = gameState.thermalProfiles[icefishId]?.discoveredCTMax != nil

            default:
                shouldUnlock = false
            }

            if shouldUnlock {
                newlyUnlockable.append(organism)
            }
        }

        return newlyUnlockable
    }

    /// Check which handbook entries should be unlocked based on the latest experiment.
    static func checkHandbookUnlocks(
        experiment: Experiment,
        result: ExperimentResult,
        organism: Organism,
        gameState: GameState
    ) -> [String] {
        var newKeys: [String] = []
        let unlocked = gameState.unlockedHandbookEntries

        // independent_variables: correct IV for whatever question was asked
        if experiment.researchQuestion.ivCredit(for: experiment.independentVariable) == 2
            && !unlocked.contains("independent_variables") {
            newKeys.append("independent_variables")
        }

        // dependent_variables: correct DV (full credit)
        if dvScore(question: experiment.researchQuestion, dv: experiment.dependentVariable) == 2
            && !unlocked.contains("dependent_variables") {
            newKeys.append("dependent_variables")
        }

        // control_groups: has control group
        if experiment.hasControlGroup
            && !unlocked.contains("control_groups") {
            newKeys.append("control_groups")
        }

        // controlled_variables: controlled a variable organism is sensitive to
        if firstControlledSensitiveVariable(experiment: experiment, organism: organism) != nil
            && !unlocked.contains("controlled_variables") {
            newKeys.append("controlled_variables")
        }

        // sample_size: sampleSize >= 30
        if experiment.sampleSize >= 30
            && !unlocked.contains("sample_size") {
            newKeys.append("sample_size")
        }

        // confounding_variables: confidence < 4 AND missed a sensitive variable
        if result.confidenceRating < 4
            && firstMissingSensitiveVariable(experiment: experiment, organism: organism) != nil
            && !unlocked.contains("confounding_variables") {
            newKeys.append("confounding_variables")
        }

        // reproducibility: 3+ experiments on same organism
        if let profile = gameState.thermalProfiles[experiment.organismId] {
            // Current result hasn't been logged yet, so count + 1
            if profile.experimentHistory.count + 1 >= 3
                && !unlocked.contains("reproducibility") {
                newKeys.append("reproducibility")
            }
        }

        // experimental_design: confidence == 5
        if result.confidenceRating == 5
            && !unlocked.contains("experimental_design") {
            newKeys.append("experimental_design")
        }

        return newKeys
    }
}
