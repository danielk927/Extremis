import Foundation

// MARK: - Enums

enum ResearchQuestion: String, Codable, CaseIterable, Identifiable, Sendable {
    case ctmax
    case thermalOptimum
    case acclimationCapacity
    case heatShockResponse
    case uvResistance
    case desiccationTolerance

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ctmax: "Critical Thermal Maximum"
        case .thermalOptimum: "Thermal Optimum"
        case .acclimationCapacity: "Acclimation Capacity"
        case .heatShockResponse: "Heat Shock Response"
        case .uvResistance: "UV Resistance"
        case .desiccationTolerance: "Desiccation Tolerance"
        }
    }

    /// The independent variable that, when chosen, earns full IV credit for this question.
    var correctIndependentVariable: IndependentVariable {
        switch self {
        case .ctmax, .thermalOptimum, .acclimationCapacity, .heatShockResponse:
            return .temperature
        case .uvResistance:
            return .lightLevel
        case .desiccationTolerance:
            return .exposureDuration
        }
    }

    /// Returns the IV credit (0 or 2) for the given independent variable.
    /// Some questions accept more than one valid IV (e.g. desiccation accepts both
    /// Exposure Duration and Humidity).
    func ivCredit(for iv: IndependentVariable) -> Int {
        if iv == correctIndependentVariable { return 2 }
        switch (self, iv) {
        case (.desiccationTolerance, .humidity): return 2
        default: return 0
        }
    }

    // MARK: - Chart / axis metadata

    /// Whether this question is driven by temperature as the stimulus.
    var isTemperatureBased: Bool {
        switch self {
        case .ctmax, .thermalOptimum, .acclimationCapacity, .heatShockResponse: return true
        case .uvResistance, .desiccationTolerance: return false
        }
    }

    /// X-axis label for charts and the runner display.
    var xAxisLabel: String {
        switch self {
        case .ctmax, .thermalOptimum, .acclimationCapacity, .heatShockResponse:
            return "Temperature (°C)"
        case .uvResistance:
            return "UV Dose (J/m²)"
        case .desiccationTolerance:
            return "Desiccation Time (hrs)"
        }
    }

    /// Fixed x display range for non-thermal questions; nil means use organism thermal range.
    var xDisplayRange: ClosedRange<Double>? {
        switch self {
        case .ctmax, .thermalOptimum, .acclimationCapacity, .heatShockResponse:
            return nil
        case .uvResistance:
            return 0...1000
        case .desiccationTolerance:
            return 0...168
        }
    }

    /// Unit string appended to the scalar measured value (empty for 0–1 ratios).
    var measuredValueUnit: String {
        switch self {
        case .ctmax, .thermalOptimum: return "°C"
        case .acclimationCapacity, .heatShockResponse, .uvResistance, .desiccationTolerance: return ""
        }
    }

    /// The (low, high) sweep range used by the experiment runner animation.
    func stimulusRange(organism: Organism) -> (lo: Double, hi: Double) {
        switch self {
        case .ctmax, .thermalOptimum, .acclimationCapacity, .heatShockResponse:
            return (22.0, organism.trueCTMax + 5.0)
        case .uvResistance:
            return (0.0, 1000.0)
        case .desiccationTolerance:
            return (0.0, 168.0)
        }
    }

    /// Human-readable label for the live stimulus value shown during the runner animation.
    var stimulusUnit: String {
        switch self {
        case .ctmax, .thermalOptimum, .acclimationCapacity, .heatShockResponse: return "°C"
        case .uvResistance: return "J/m²"
        case .desiccationTolerance: return "hrs"
        }
    }

    /// Chart title shown in the runner and results screens.
    var chartTitle: String {
        switch self {
        case .ctmax, .thermalOptimum, .acclimationCapacity, .heatShockResponse:
            return "Thermal Performance Curve"
        case .uvResistance:
            return "UV Dose-Response Curve"
        case .desiccationTolerance:
            return "Desiccation Survival Curve"
        }
    }
}

enum IndependentVariable: String, Codable, CaseIterable, Identifiable, Sendable {
    case temperature
    case exposureDuration
    case lightLevel
    case humidity

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .temperature: "Temperature"
        case .exposureDuration: "Exposure Duration"
        case .lightLevel: "Light Level"
        case .humidity: "Humidity"
        }
    }

    /// Label shown on the chart x-axis when this IV is in use.
    var axisLabel: String {
        switch self {
        case .temperature:      return "Temperature (°C)"
        case .exposureDuration: return "Time (hrs)"
        case .lightLevel:       return "UV Dose (J/m²)"
        case .humidity:         return "Humidity (%)"
        }
    }

    /// Fixed x display range for the chart. Nil = use organism's thermal range.
    var xDisplayRange: ClosedRange<Double>? {
        switch self {
        case .temperature:      return nil
        case .exposureDuration: return 0...168
        case .lightLevel:       return 0...1000
        case .humidity:         return 0...100
        }
    }

    /// Unit shown beside the live stimulus value in the experiment runner.
    var stimulusUnit: String {
        switch self {
        case .temperature:      return "°C"
        case .exposureDuration: return "hrs"
        case .lightLevel:       return "J/m²"
        case .humidity:         return "%"
        }
    }
}

enum DependentVariable: String, Codable, CaseIterable, Identifiable, Sendable {
    case survivalRate
    case movementSpeed
    case growthRate
    case proteinActivity

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .survivalRate: "Survival Rate"
        case .movementSpeed: "Movement Speed"
        case .growthRate: "Growth Rate"
        case .proteinActivity: "Protein Activity"
        }
    }

    /// Label shown on the chart y-axis when this DV is in use.
    var axisLabel: String {
        switch self {
        case .survivalRate:    return "Survival (%)"
        case .movementSpeed:   return "Speed (mm/s)"
        case .growthRate:      return "Growth Rate"
        case .proteinActivity: return "Protein Activity"
        }
    }

    /// The actual measurement range that normalized 0...1 maps to.
    var yRange: ClosedRange<Double> {
        switch self {
        case .survivalRate:    return 0...100
        case .movementSpeed:   return 0...10
        case .growthRate:      return 0...5
        case .proteinActivity: return 0...1
        }
    }

    /// Five y-axis tick labels from top (max) to bottom (0), matching the chart's 25%-spaced grid lines.
    var yAxisTicks: [String] {
        switch self {
        case .survivalRate:
            return ["100%", "75%", "50%", "25%", "0%"]
        case .movementSpeed:
            return ["10.0", "7.5", "5.0", "2.5", "0.0"]
        case .growthRate:
            return ["5.0", "3.8", "2.5", "1.3", "0.0"]
        case .proteinActivity:
            return ["1.00", "0.75", "0.50", "0.25", "0.00"]
        }
    }
}

enum ControlledVariable: String, Codable, CaseIterable, Identifiable, Sendable {
    case humidity
    case light
    case food
    case specimenAge
    case samplePrepTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .humidity: "Humidity"
        case .light: "Light"
        case .food: "Food"
        case .specimenAge: "Specimen Age"
        case .samplePrepTime: "Sample Prep Time"
        }
    }
}

// MARK: - Experiment

struct Experiment: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var organismId: UUID
    var researchQuestion: ResearchQuestion
    var independentVariable: IndependentVariable
    var dependentVariable: DependentVariable
    var controlledVariables: Set<ControlledVariable>
    var hasControlGroup: Bool
    var sampleSize: Int
    var timestamp: Date = Date()
}

// MARK: - Supporting Types

struct FeedbackItem: Codable, Sendable {
    var message: String
    var isPositive: Bool
}

struct DataPoint: Codable, Sendable {
    var x: Double
    var y: Double
}

// MARK: - ExperimentResult

struct ExperimentResult: Identifiable, Codable, Sendable {
    var id: UUID
    var experimentId: UUID
    var researchQuestion: ResearchQuestion
    /// The IV the user chose — drives the chart x-axis label and range.
    var independentVariable: IndependentVariable
    /// The DV the user chose — drives the chart y-axis label.
    var dependentVariable: DependentVariable
    /// True when IV and DV are both valid for this research question.
    var isRelevantCombination: Bool
    var measuredValue: Double
    var confidenceRating: Int
    var errorMargin: Double
    var feedbackItems: [FeedbackItem]
    var rawDataPoints: [DataPoint]

    /// Chart title: question-specific when IV/DV are relevant; generic "[DV] vs. [IV]" otherwise.
    var dynamicChartTitle: String {
        isRelevantCombination
            ? researchQuestion.chartTitle
            : "\(dependentVariable.displayName) vs. \(independentVariable.displayName)"
    }

    // MARK: Explicit init (used by ExperimentEngine)

    init(
        experimentId: UUID,
        researchQuestion: ResearchQuestion,
        independentVariable: IndependentVariable,
        dependentVariable: DependentVariable,
        isRelevantCombination: Bool,
        measuredValue: Double,
        confidenceRating: Int,
        errorMargin: Double,
        feedbackItems: [FeedbackItem],
        rawDataPoints: [DataPoint]
    ) {
        self.id = UUID()
        self.experimentId = experimentId
        self.researchQuestion = researchQuestion
        self.independentVariable = independentVariable
        self.dependentVariable = dependentVariable
        self.isRelevantCombination = isRelevantCombination
        self.measuredValue = measuredValue
        self.confidenceRating = confidenceRating
        self.errorMargin = errorMargin
        self.feedbackItems = feedbackItems
        self.rawDataPoints = rawDataPoints
    }

    // MARK: Backward-compatible Codable (handles old saves missing IV/DV fields)

    enum CodingKeys: String, CodingKey {
        case id, experimentId, researchQuestion
        case independentVariable, dependentVariable, isRelevantCombination
        case measuredValue, confidenceRating, errorMargin, feedbackItems, rawDataPoints
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        experimentId = try c.decode(UUID.self, forKey: .experimentId)
        researchQuestion = try c.decode(ResearchQuestion.self, forKey: .researchQuestion)
        independentVariable = (try? c.decode(IndependentVariable.self, forKey: .independentVariable)) ?? .temperature
        dependentVariable = (try? c.decode(DependentVariable.self, forKey: .dependentVariable)) ?? .survivalRate
        isRelevantCombination = (try? c.decode(Bool.self, forKey: .isRelevantCombination)) ?? false
        measuredValue = try c.decode(Double.self, forKey: .measuredValue)
        confidenceRating = try c.decode(Int.self, forKey: .confidenceRating)
        errorMargin = try c.decode(Double.self, forKey: .errorMargin)
        feedbackItems = try c.decode([FeedbackItem].self, forKey: .feedbackItems)
        rawDataPoints = try c.decode([DataPoint].self, forKey: .rawDataPoints)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(experimentId, forKey: .experimentId)
        try c.encode(researchQuestion, forKey: .researchQuestion)
        try c.encode(independentVariable, forKey: .independentVariable)
        try c.encode(dependentVariable, forKey: .dependentVariable)
        try c.encode(isRelevantCombination, forKey: .isRelevantCombination)
        try c.encode(measuredValue, forKey: .measuredValue)
        try c.encode(confidenceRating, forKey: .confidenceRating)
        try c.encode(errorMargin, forKey: .errorMargin)
        try c.encode(feedbackItems, forKey: .feedbackItems)
        try c.encode(rawDataPoints, forKey: .rawDataPoints)
    }
}
