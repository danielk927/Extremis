import SwiftUI

// MARK: - Challenge Tier

enum ChallengeTier: String, CaseIterable, Hashable {
    case novice, intermediate, expert

    var displayName: String {
        switch self {
        case .novice:       return "Novice"
        case .intermediate: return "Intermediate"
        case .expert:       return "Expert"
        }
    }

    var emoji: String {
        switch self {
        case .novice:       return "🌱"
        case .intermediate: return "🔬"
        case .expert:       return "🧬"
        }
    }

    var tintColor: Color {
        switch self {
        case .novice:       return Color(hex: "E8F0E0")
        case .intermediate: return Color(hex: "FFF3E0")
        case .expert:       return Color(hex: "F3E5F5")
        }
    }
}

// MARK: - Challenge Model

/// A research challenge whose completion is computed live from GameState.
struct Challenge: Identifiable {
    let id: String
    let name: String
    let description: String
    let tier: ChallengeTier
    /// Human-readable condition shown on the card when incomplete.
    let requirement: String
    /// Returns true when the challenge conditions are satisfied.
    let isCompleted: @Sendable (GameState) -> Bool
}

// MARK: - Challenge Database

enum ChallengeDatabase {

    static let all: [Challenge] = [

        // MARK: Novice

        Challenge(
            id: "first_discovery",
            name: "First Discovery",
            description: "Discover any thermal property for any organism.",
            tier: .novice,
            requirement: "Discover any CTMax, Optimum, Acclimation, or Heat Shock value",
            isCompleted: { state in
                state.thermalProfiles.values.contains {
                    $0.discoveredCTMax != nil
                    || $0.discoveredOptimum != nil
                    || $0.discoveredAcclimation != nil
                    || $0.discoveredHeatShock != nil
                }
            }
        ),

        Challenge(
            id: "controlled_chaos",
            name: "Controlled Chaos",
            description: "Experience firsthand how experimental design quality shapes your confidence in results.",
            tier: .novice,
            requirement: "Have a ★★ or lower AND a ★★★★ or higher result for the same organism",
            isCompleted: { state in
                state.thermalProfiles.values.contains { profile in
                    let hasLow  = profile.experimentHistory.contains { $0.confidenceRating <= 2 }
                    let hasHigh = profile.experimentHistory.contains { $0.confidenceRating >= 4 }
                    return hasLow && hasHigh
                }
            }
        ),

        Challenge(
            id: "acclimation_effect",
            name: "The Acclimation Effect",
            description: "Measure how an organism shifts its thermal tolerance after gradual exposure to warmer conditions.",
            tier: .novice,
            requirement: "Complete an Acclimation Capacity experiment at ★★★ or higher",
            isCompleted: { state in
                state.thermalProfiles.values.contains { ($0.acclimationConfidence ?? 0) >= 3 }
            }
        ),

        // MARK: Intermediate

        Challenge(
            id: "clean_read",
            name: "Clean Read",
            description: "Design a perfect experiment — correct IV, correct DV, control group, and adequate sample.",
            tier: .intermediate,
            requirement: "Achieve ★★★★★ confidence on any experiment",
            isCompleted: { state in
                state.highestConfidenceAchieved >= 5
            }
        ),

        Challenge(
            id: "fragile_world",
            name: "Fragile World",
            description: "Study an organism whose entire thermal tolerance fits within a single degree of summer warming.",
            tier: .intermediate,
            requirement: "Discover the CTMax of an organism with a thermal range under 10 °C",
            isCompleted: { state in
                OrganismDatabase.allOrganisms
                    .filter { $0.trueThermalRangeMax - $0.trueThermalRangeMin < 10 }
                    .contains { org in state.thermalProfiles[org.id]?.discoveredCTMax != nil }
            }
        ),

        Challenge(
            id: "three_degree",
            name: "3-Degree Catastrophe",
            description: "Discover an organism so thermally sensitive that a few degrees of warming threatens its survival.",
            tier: .intermediate,
            requirement: "Find an organism where CTMax − Optimum ≤ 8 °C",
            isCompleted: { state in
                OrganismDatabase.allOrganisms.contains { org in
                    guard let profile = state.thermalProfiles[org.id],
                          let ctmax   = profile.discoveredCTMax,
                          let opt     = profile.discoveredOptimum
                    else { return false }
                    return (ctmax - opt) <= 8
                }
            }
        ),

        // MARK: Expert

        Challenge(
            id: "extremophile_hunter",
            name: "Extremophile Hunter",
            description: "Find a heat-resistant organism living beyond the limits most life can tolerate.",
            tier: .expert,
            requirement: "Discover a CTMax above 50 °C",
            isCompleted: { state in
                state.thermalProfiles.values.contains { ($0.discoveredCTMax ?? 0) > 50 }
            }
        ),

        Challenge(
            id: "complete_researcher",
            name: "Complete Researcher",
            description: "Master the full thermal biology of one species — every parameter, measured with precision.",
            tier: .expert,
            requirement: "Fully complete any organism's profile at ★★★★ or better for all four fields",
            isCompleted: { state in
                state.thermalProfiles.values.contains { $0.isFullyMastered }
            }
        ),
    ]

    /// Returns all challenges for a specific tier, in insertion order.
    static func challenges(for tier: ChallengeTier) -> [Challenge] {
        all.filter { $0.tier == tier }
    }

    /// Returns the total number of completed challenges for a given game state.
    static func completedCount(for gameState: GameState) -> Int {
        all.filter { $0.isCompleted(gameState) }.count
    }
}
