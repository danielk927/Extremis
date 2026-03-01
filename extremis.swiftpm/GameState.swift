import Foundation
import Observation

@Observable
class GameState: Codable, @unchecked Sendable {
    var unlockedOrganismIds: Set<UUID> = []
    var totalExperimentsRun: Int = 0
    var highestConfidenceAchieved: Int = 0
    var completedChallengeIds: Set<UUID> = []
    var unlockedHandbookEntries: Set<String> = []
    var thermalProfiles: [UUID: ThermalProfile] = [:]
    var hasSeenOnboarding: Bool = false
    var firstExperimentComplete: Bool = false

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case unlockedOrganismIds, totalExperimentsRun, highestConfidenceAchieved
        case completedChallengeIds, unlockedHandbookEntries, thermalProfiles
        case hasSeenOnboarding, firstExperimentComplete
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        unlockedOrganismIds = try c.decode(Set<UUID>.self, forKey: .unlockedOrganismIds)
        totalExperimentsRun = try c.decode(Int.self, forKey: .totalExperimentsRun)
        highestConfidenceAchieved = try c.decode(Int.self, forKey: .highestConfidenceAchieved)
        completedChallengeIds = try c.decode(Set<UUID>.self, forKey: .completedChallengeIds)
        unlockedHandbookEntries = try c.decode(Set<String>.self, forKey: .unlockedHandbookEntries)
        thermalProfiles = try c.decode([UUID: ThermalProfile].self, forKey: .thermalProfiles)
        hasSeenOnboarding = try c.decode(Bool.self, forKey: .hasSeenOnboarding)
        firstExperimentComplete = try c.decode(Bool.self, forKey: .firstExperimentComplete)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(unlockedOrganismIds, forKey: .unlockedOrganismIds)
        try c.encode(totalExperimentsRun, forKey: .totalExperimentsRun)
        try c.encode(highestConfidenceAchieved, forKey: .highestConfidenceAchieved)
        try c.encode(completedChallengeIds, forKey: .completedChallengeIds)
        try c.encode(unlockedHandbookEntries, forKey: .unlockedHandbookEntries)
        try c.encode(thermalProfiles, forKey: .thermalProfiles)
        try c.encode(hasSeenOnboarding, forKey: .hasSeenOnboarding)
        try c.encode(firstExperimentComplete, forKey: .firstExperimentComplete)
    }

    // MARK: Persistence

    private static var saveURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("thermal_game_state.json")
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.saveURL, options: .atomic)
    }

    static func load() -> GameState {
        guard let data = try? Data(contentsOf: saveURL),
              let state = try? JSONDecoder().decode(GameState.self, from: data)
        else {
            let fresh = GameState()
            fresh.unlockedOrganismIds = OrganismDatabase.starterOrganismIds
            return fresh
        }
        return state
    }

    // MARK: Helpers

    /// Get the profile for an organism, creating a blank one if needed.
    func profileFor(_ organismId: UUID) -> ThermalProfile {
        if let existing = thermalProfiles[organismId] {
            return existing
        }
        let profile = ThermalProfile(id: organismId, organismId: organismId)
        thermalProfiles[organismId] = profile
        return profile
    }

    /// Record an experiment result against an organism's profile, updating the best discovered value.
    func logExperiment(_ result: ExperimentResult, for organismId: UUID) {
        var profile = profileFor(organismId)
        profile.experimentHistory.append(result)

        // Update discovered value when the new result beats the stored confidence.
        switch result.researchQuestion {
        case .ctmax:
            if result.confidenceRating >= (profile.ctmaxConfidence ?? 0) {
                profile.discoveredCTMax = result.measuredValue
                profile.ctmaxConfidence = result.confidenceRating
            }
        case .thermalOptimum:
            if result.confidenceRating >= (profile.optimumConfidence ?? 0) {
                profile.discoveredOptimum = result.measuredValue
                profile.optimumConfidence = result.confidenceRating
            }
        case .acclimationCapacity:
            if result.confidenceRating >= (profile.acclimationConfidence ?? 0) {
                profile.discoveredAcclimation = result.measuredValue
                profile.acclimationConfidence = result.confidenceRating
            }
        case .heatShockResponse:
            if result.confidenceRating >= (profile.heatShockConfidence ?? 0) {
                profile.discoveredHeatShock = result.measuredValue
                profile.heatShockConfidence = result.confidenceRating
            }
        case .uvResistance:
            if result.confidenceRating >= (profile.uvResistanceConfidence ?? 0) {
                profile.discoveredUVResistance = result.measuredValue
                profile.uvResistanceConfidence = result.confidenceRating
            }
        case .desiccationTolerance:
            if result.confidenceRating >= (profile.desiccationToleranceConfidence ?? 0) {
                profile.discoveredDesiccationTolerance = result.measuredValue
                profile.desiccationToleranceConfidence = result.confidenceRating
            }
        }

        thermalProfiles[organismId] = profile
        totalExperimentsRun += 1
        if result.confidenceRating > highestConfidenceAchieved {
            highestConfidenceAchieved = result.confidenceRating
        }
        if !firstExperimentComplete {
            firstExperimentComplete = true
        }
    }
}
