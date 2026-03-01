import Foundation
import SwiftUI

// MARK: - Color(hex:) Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Organism

struct Organism: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var commonName: String
    var description: String
    var tier: Tier
    var signatureColorHex: String
    var iconName: String
    var unlockCondition: String

    // Hidden true thermal parameters
    var trueCTMax: Double
    var trueThermalOptimum: Double
    var trueAcclimationCapacity: Double
    var trueHeatShockResponse: Double
    var trueThermalRangeMin: Double
    var trueThermalRangeMax: Double

    // Confounding variable sensitivities
    var sensitiveToAge: Bool
    var sensitiveToHumidity: Bool
    var sensitiveToLight: Bool
    var sensitiveToFood: Bool

    // Hidden true non-thermal parameters (0.0 = none, 1.0 = extreme)
    var trueUVResistance: Double
    var trueDesiccationTolerance: Double

    // UV dose-response curve: sigmoid decay survival(dose) = 1/(1+exp(steepness*(dose-LD50)))
    var uvLD50: Double        // J/m² dose at which 50% of specimens die
    var uvSteepness: Double   // sigmoid slope (higher = sharper drop-off)

    // Desiccation survival curve: survival(t) = (1-baseline)*exp(-decayRate*max(0,t-lag))+baseline
    var desiccationLag: Double       // hours before survival begins to drop
    var desiccationDecayRate: Double // exponential decay rate after the lag period
    var desiccationBaseline: Double  // minimum survival floor (0 = lethal; >0 = anhydrobiosis)

    var funFact: String

    // MARK: Computed

    var signatureColorValue: Color {
        Color(hex: signatureColorHex)
    }

    // MARK: Tier

    enum Tier: String, Codable, CaseIterable, Identifiable, Sendable {
        case starter
        case intermediate
        case advanced

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .starter: "Starter"
            case .intermediate: "Intermediate"
            case .advanced: "Advanced"
            }
        }
    }
}
