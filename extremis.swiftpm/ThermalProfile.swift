import Foundation

struct ThermalProfile: Identifiable, Codable, Sendable {
    var id: UUID
    var organismId: UUID

    // Discovered values (nil until user runs a valid experiment)
    var discoveredCTMax: Double?
    var ctmaxConfidence: Int?
    var discoveredOptimum: Double?
    var optimumConfidence: Int?
    var discoveredAcclimation: Double?
    var acclimationConfidence: Int?
    var discoveredHeatShock: Double?
    var heatShockConfidence: Int?
    var discoveredUVResistance: Double?
    var uvResistanceConfidence: Int?
    var discoveredDesiccationTolerance: Double?
    var desiccationToleranceConfidence: Int?

    var experimentHistory: [ExperimentResult] = []

    // MARK: Computed

    /// Fraction of the 6 discoverable fields that have been filled (0.0–1.0).
    var completionPercentage: Double {
        let fields: [Any?] = [
            discoveredCTMax, discoveredOptimum,
            discoveredAcclimation, discoveredHeatShock,
            discoveredUVResistance, discoveredDesiccationTolerance,
        ]
        let discovered = fields.compactMap { $0 }.count
        return Double(discovered) / 6.0
    }

    /// All 6 fields have at least one measurement.
    var isComplete: Bool {
        discoveredCTMax != nil
            && discoveredOptimum != nil
            && discoveredAcclimation != nil
            && discoveredHeatShock != nil
            && discoveredUVResistance != nil
            && discoveredDesiccationTolerance != nil
    }

    /// All 6 fields discovered with confidence >= 4.
    var isFullyMastered: Bool {
        guard isComplete else { return false }
        return (ctmaxConfidence ?? 0) >= 4
            && (optimumConfidence ?? 0) >= 4
            && (acclimationConfidence ?? 0) >= 4
            && (heatShockConfidence ?? 0) >= 4
            && (uvResistanceConfidence ?? 0) >= 4
            && (desiccationToleranceConfidence ?? 0) >= 4
    }
}
