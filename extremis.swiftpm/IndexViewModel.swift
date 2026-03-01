import Foundation
import Observation

/// View model driving the Extremis home screen.
@Observable
class IndexViewModel {
    /// Persisted game state, loaded from disk on init.
    var gameState: GameState
    /// All organisms in the database.
    var allOrganisms: [Organism] = OrganismDatabase.allOrganisms
    /// Navigation path for the Index tab — set to [] to pop to root from anywhere.
    var navigationPath: [UUID] = []

    init() {
        self.gameState = GameState.load()
        // Ensure starter organisms are always unlocked
        for id in OrganismDatabase.starterOrganismIds {
            gameState.unlockedOrganismIds.insert(id)
        }
    }

    // MARK: - Computed

    /// Organisms the player has unlocked.
    var unlockedOrganisms: [Organism] {
        allOrganisms.filter { gameState.unlockedOrganismIds.contains($0.id) }
    }

    /// Organisms still locked.
    var lockedOrganisms: [Organism] {
        allOrganisms.filter { !gameState.unlockedOrganismIds.contains($0.id) }
    }

    /// Fraction of all discoverable fields across all unlocked organisms (0.0–1.0).
    var overallProgress: Double {
        guard !unlockedOrganisms.isEmpty else { return 0 }
        let total = Double(unlockedOrganisms.count) * 6.0
        let discovered = unlockedOrganisms.reduce(0.0) { sum, org in
            sum + profileFor(org).completionPercentage * 6.0
        }
        return discovered / total
    }

    /// Total number of fields discovered across all organisms.
    var totalDiscovered: Int {
        unlockedOrganisms.reduce(0) { sum, org in
            let p = profileFor(org)
            var count = 0
            if p.discoveredCTMax != nil { count += 1 }
            if p.discoveredOptimum != nil { count += 1 }
            if p.discoveredAcclimation != nil { count += 1 }
            if p.discoveredHeatShock != nil { count += 1 }
            if p.discoveredUVResistance != nil { count += 1 }
            if p.discoveredDesiccationTolerance != nil { count += 1 }
            return sum + count
        }
    }

    /// Total discoverable fields across all unlocked organisms (6 per organism).
    var totalDiscoverable: Int {
        unlockedOrganisms.count * 6
    }

    /// Sorted list: unlocked organisms first (by tier), then locked (by tier).
    var sortedOrganisms: [Organism] {
        let tierOrder: [Organism.Tier] = [.starter, .intermediate, .advanced]
        let unlocked = unlockedOrganisms.sorted { tierOrder.firstIndex(of: $0.tier) ?? 0 < tierOrder.firstIndex(of: $1.tier) ?? 0 }
        let locked = lockedOrganisms.sorted { tierOrder.firstIndex(of: $0.tier) ?? 0 < tierOrder.firstIndex(of: $1.tier) ?? 0 }
        return unlocked + locked
    }

    // MARK: - Helpers

    /// Whether the given organism is unlocked.
    func isUnlocked(_ organism: Organism) -> Bool {
        gameState.unlockedOrganismIds.contains(organism.id)
    }

    /// Get the thermal profile for an organism.
    func profileFor(_ organism: Organism) -> ThermalProfile {
        gameState.profileFor(organism.id)
    }
}
