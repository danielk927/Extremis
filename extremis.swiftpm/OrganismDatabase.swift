import Foundation

struct OrganismDatabase: Sendable {

    // Fixed UUIDs so references remain stable across launches.
    private static let ecoliId        = UUID(uuidString: "00000001-0001-0001-0001-000000000001")!
    private static let drosophilaId   = UUID(uuidString: "00000001-0001-0001-0001-000000000002")!
    private static let elegansId      = UUID(uuidString: "00000001-0001-0001-0001-000000000003")!
    private static let coralId        = UUID(uuidString: "00000001-0001-0001-0001-000000000004")!
    private static let beetleId       = UUID(uuidString: "00000001-0001-0001-0001-000000000005")!
    private static let icefishId      = UUID(uuidString: "00000001-0001-0001-0001-000000000006")!
    private static let tardigradeId   = UUID(uuidString: "00000001-0001-0001-0001-000000000007")!
    private static let pompeiiWormId  = UUID(uuidString: "00000001-0001-0001-0001-000000000008")!
    private static let silverAntId    = UUID(uuidString: "00000001-0001-0001-0001-000000000009")!
    private static let woodFrogId     = UUID(uuidString: "00000001-0001-0001-0001-00000000000A")!

    /// The three organisms available from the start.
    static let starterOrganismIds: Set<UUID> = [ecoliId, drosophilaId, elegansId]

    // MARK: - All Organisms

    static let allOrganisms: [Organism] = [

        // ── Tier 1 — Starter ────────────────────────────────────────────

        Organism(
            id: ecoliId,
            name: "Escherichia coli",
            commonName: "E. coli",
            description: "A rod-shaped bacteria commonly found in the intestines of humans and animals. While most strains are harmless, some produce toxins that cause severe stomach cramps, diarrhea, and vomiting.",
            tier: .starter,
            signatureColorHex: "D4A84B",
            iconName: "ecoli",
            unlockCondition: "Available from start",
            trueCTMax: 46.5,
            trueThermalOptimum: 37,
            trueAcclimationCapacity: 0.3,
            trueHeatShockResponse: 0.9,
            trueThermalRangeMin: 8,
            trueThermalRangeMax: 46.5,
            sensitiveToAge: false,
            sensitiveToHumidity: false,
            sensitiveToLight: true,
            sensitiveToFood: true,
            trueUVResistance: 0.15,
            trueDesiccationTolerance: 0.10,
            uvLD50: 50,          uvSteepness: 0.060,
            desiccationLag: 1,   desiccationDecayRate: 0.30, desiccationBaseline: 0.02,
            funFact: "E. coli can divide every 20 minutes under optimal conditions, producing over 4 billion descendants in a single day."
        ),

        Organism(
            id: drosophilaId,
            name: "Drosophila melanogaster",
            commonName: "Fruit Fly",
            description: "A small fruit fly that has been widely used as model organisms for scientific experiments due to their fast two-week life cycle and simple genetics.",
            tier: .starter,
            signatureColorHex: "C4813D",
            iconName: "drosophila",
            unlockCondition: "Available from start",
            trueCTMax: 39.5,
            trueThermalOptimum: 25,
            trueAcclimationCapacity: 0.5,
            trueHeatShockResponse: 0.5,
            trueThermalRangeMin: 11,
            trueThermalRangeMax: 39.5,
            sensitiveToAge: true,
            sensitiveToHumidity: true,
            sensitiveToLight: false,
            sensitiveToFood: true,
            trueUVResistance: 0.25,
            trueDesiccationTolerance: 0.30,
            uvLD50: 80,          uvSteepness: 0.040,
            desiccationLag: 4,   desiccationDecayRate: 0.15, desiccationBaseline: 0.03,
            funFact: "Fruit flies share about 60% of their DNA with humans and have a 24-hour circadian rhythm similar to humans."
        ),

        Organism(
            id: elegansId,
            name: "Caenorhabditis elegans",
            commonName: "C. elegans",
            description: "A small, transparent roundworm that lives in the soil. It is the first multicellular organism to have its genome fully sequenced.",
            tier: .starter,
            signatureColorHex: "9B8EC4",
            iconName: "celegans",
            unlockCondition: "Available from start",
            trueCTMax: 36,
            trueThermalOptimum: 20,
            trueAcclimationCapacity: 0.4,
            trueHeatShockResponse: 0.6,
            trueThermalRangeMin: 12,
            trueThermalRangeMax: 36,
            sensitiveToAge: true,
            sensitiveToHumidity: true,
            sensitiveToLight: false,
            sensitiveToFood: true,
            trueUVResistance: 0.15,
            trueDesiccationTolerance: 0.20,
            uvLD50: 60,          uvSteepness: 0.050,
            desiccationLag: 3,   desiccationDecayRate: 0.20, desiccationBaseline: 0.02,
            funFact: "C. elegans was the first animal to have every single neural connection mapped, which includes all 302 neurons and 7,000 synapses."
        ),

        // ── Tier 2 — Intermediate ───────────────────────────────────────

        Organism(
            id: coralId,
            name: "Acropora millepora",
            commonName: "Reef Coral",
            description: "A branching stony coral found in tropical reefs. It is extremely sensitive to temperature changes, experiencing significant bleaching and death when temperatures exceed 31°C.",
            tier: .intermediate,
            signatureColorHex: "C0525E",
            iconName: "reef_coral",
            unlockCondition: "Complete any organism card",
            trueCTMax: 36,
            trueThermalOptimum: 27,
            trueAcclimationCapacity: 0.2,
            trueHeatShockResponse: 0.3,
            trueThermalRangeMin: 18,
            trueThermalRangeMax: 36,
            sensitiveToAge: true,
            sensitiveToHumidity: false,
            sensitiveToLight: true,
            sensitiveToFood: false,
            trueUVResistance: 0.40,
            trueDesiccationTolerance: 0.05,
            uvLD50: 200,         uvSteepness: 0.015,
            desiccationLag: 0.5, desiccationDecayRate: 0.80, desiccationBaseline: 0.00,
            funFact: "Corals get their vibrant colors from symbiotic algae. When stressed by heat, they expel the algae and turn white in a process called bleaching."
        ),

        Organism(
            id: beetleId,
            name: "Onymacris unguicularis",
            commonName: "Desert Beetle",
            description: "A beetle from the Namib Desert of southwestern Africa known for collecting water from coastal fog while performing a 'head-stand'.",
            tier: .intermediate,
            signatureColorHex: "C4A86B",
            iconName: "desert_beetle",
            unlockCondition: "Achieve 4-star confidence",
            trueCTMax: 52,
            trueThermalOptimum: 35,
            trueAcclimationCapacity: 0.4,
            trueHeatShockResponse: 0.6,
            trueThermalRangeMin: 5,
            trueThermalRangeMax: 52,
            sensitiveToAge: true,
            sensitiveToHumidity: true,
            sensitiveToLight: false,
            sensitiveToFood: false,
            trueUVResistance: 0.80,
            trueDesiccationTolerance: 0.90,
            uvLD50: 600,         uvSteepness: 0.008,
            desiccationLag: 72,  desiccationDecayRate: 0.04, desiccationBaseline: 0.20,
            funFact: "The desert beetle does a headstand in the fog, letting water droplets roll down its bumpy shell straight into its mouth."
        ),

        Organism(
            id: icefishId,
            name: "Channichthyidae",
            commonName: "Antarctic Icefish",
            description: "The only vertebrate with no red blood cells or hemoglobin. It can survive in sub-zero Antarctic waters using antifreeze proteins.",
            tier: .intermediate,
            signatureColorHex: "7BB8D4",
            iconName: "antarctic_icefish",
            unlockCondition: "Run 10 experiments",
            trueCTMax: 12,
            trueThermalOptimum: 1,
            trueAcclimationCapacity: 0.1,
            trueHeatShockResponse: 0.1,
            trueThermalRangeMin: -2,
            trueThermalRangeMax: 12,
            sensitiveToAge: true,
            sensitiveToHumidity: false,
            sensitiveToLight: true,
            sensitiveToFood: false,
            trueUVResistance: 0.10,
            trueDesiccationTolerance: 0.0,
            uvLD50: 25,          uvSteepness: 0.080,
            desiccationLag: 0.25, desiccationDecayRate: 2.00, desiccationBaseline: 0.00,
            funFact: "Icefish blood is completely transparent. They lost the gene for hemoglobin and rely on oxygen dissolved directly in their plasma."
        ),

        // ── Tier 3 — Advanced ───────────────────────────────────────────

        Organism(
            id: tardigradeId,
            name: "Ramazzottius varieornatus",
            commonName: "Tardigrade",
            description: "A microscopic 'water bear' known for being able to survive extreme temperatures, radiation, and desiccation.",
            tier: .advanced,
            signatureColorHex: "7A9B6D",
            iconName: "tardigrade",
            unlockCondition: "Achieve 5-star confidence",
            trueCTMax: 37,
            trueThermalOptimum: 23,
            trueAcclimationCapacity: 0.2,
            trueHeatShockResponse: 0.4,
            trueThermalRangeMin: -273,
            trueThermalRangeMax: 37,
            sensitiveToAge: false,
            sensitiveToHumidity: true,
            sensitiveToLight: false,
            sensitiveToFood: false,
            trueUVResistance: 0.85,
            trueDesiccationTolerance: 0.99,
            uvLD50: 5000,        uvSteepness: 0.0010,
            desiccationLag: 96,  desiccationDecayRate: 0.005, desiccationBaseline: 0.65,
            funFact: "Tardigrades can survive being boiled, frozen to near absolute zero, and exposed to the vacuum of space by entering a dried-out state called a tun."
        ),

        Organism(
            id: pompeiiWormId,
            name: "Alvinella pompejana",
            commonName: "Pompeii Worm",
            description: "Found at depths of around 2,500 meters under the Pacific Ocean. They have a fleece-like coating of bacteria on their backs, which they feed with their mucus.",
            tier: .advanced,
            signatureColorHex: "B83030",
            iconName: "pompeii_worm",
            unlockCondition: "Complete 3 organism cards",
            trueCTMax: 55,
            trueThermalOptimum: 42,
            trueAcclimationCapacity: 0.3,
            trueHeatShockResponse: 0.8,
            trueThermalRangeMin: 2,
            trueThermalRangeMax: 55,
            sensitiveToAge: false,
            sensitiveToHumidity: false,
            sensitiveToLight: false,
            sensitiveToFood: false,
            trueUVResistance: 0.05,
            trueDesiccationTolerance: 0.0,
            uvLD50: 20,          uvSteepness: 0.100,
            desiccationLag: 0.2, desiccationDecayRate: 2.50, desiccationBaseline: 0.00,
            funFact: "The Pompeii worm lives with its tail in 80°C water and its head in 22°C water. It is the most extreme thermal gradient tolerated by any animal."
        ),

        Organism(
            id: silverAntId,
            name: "Cataglyphis bombycina",
            commonName: "Saharan Silver Ant",
            description: "Tbe fastest ant in the world. It lives in the Sahara desert and can travel up to 855 millimeters per second, covering 108 times their body length.",
            tier: .advanced,
            signatureColorHex: "A8B0B8",
            iconName: "saharan_silver_ant",
            unlockCondition: "Complete 'Extremophile Hunter' challenge",
            trueCTMax: 53.6,
            trueThermalOptimum: 45,
            trueAcclimationCapacity: 0.2,
            trueHeatShockResponse: 0.9,
            trueThermalRangeMin: 10,
            trueThermalRangeMax: 53.6,
            sensitiveToAge: true,
            sensitiveToHumidity: true,
            sensitiveToLight: false,
            sensitiveToFood: false,
            trueUVResistance: 0.90,
            trueDesiccationTolerance: 0.85,
            uvLD50: 800,         uvSteepness: 0.006,
            desiccationLag: 60,  desiccationDecayRate: 0.03, desiccationBaseline: 0.15,
            funFact: "Saharan silver ants are coated in uniquely shaped hairs that reflect sunlight like a mirror, keeping them cool on sand that reach up to 70°C."
        ),

        Organism(
            id: woodFrogId,
            name: "Rana sylvatica",
            commonName: "Wood Frog",
            description: "A North American frog that survives winter by literally freezing solid, stopping their breathing and heartbeat.",
            tier: .advanced,
            signatureColorHex: "4A7A5B",
            iconName: "wood_frog",
            unlockCondition: "Discover Icefish CTMax",
            trueCTMax: 33,
            trueThermalOptimum: 20,
            trueAcclimationCapacity: 0.7,
            trueHeatShockResponse: 0.5,
            trueThermalRangeMin: -16,
            trueThermalRangeMax: 33,
            sensitiveToAge: true,
            sensitiveToHumidity: true,
            sensitiveToLight: true,
            sensitiveToFood: true,
            trueUVResistance: 0.20,
            trueDesiccationTolerance: 0.30,
            uvLD50: 70,          uvSteepness: 0.040,
            desiccationLag: 8,   desiccationDecayRate: 0.12, desiccationBaseline: 0.00,
            funFact: "Wood frogs produce massive amounts of glucose to protect themselves from the cold. Their blood sugar spikes to 100× normal levels to prevent ice crystals from destroying their cells."
        ),
    ]

    /// Look up an organism by its ID.
    static func organism(for id: UUID) -> Organism? {
        allOrganisms.first { $0.id == id }
    }
}
