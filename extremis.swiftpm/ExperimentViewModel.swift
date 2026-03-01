import Foundation
import Observation

/// Manages all mutable state for designing and running a single experiment.
@Observable
class ExperimentViewModel {

    // MARK: - Design State

    /// The organism being studied.
    var selectedOrganism: Organism
    /// The research question guiding the experiment.
    var researchQuestion: ResearchQuestion
    /// The variable the user will change.
    var independentVariable: IndependentVariable? = nil
    /// The variable the user will measure.
    var dependentVariable: DependentVariable? = nil
    /// Variables held constant throughout the experiment.
    var controlledVariables: Set<ControlledVariable> = []
    /// Whether a room-temperature control group is included.
    var hasControlGroup: Bool = false
    /// Number of specimens in the experiment.
    var sampleSize: Int = 20

    // MARK: - Run State

    /// The Experiment struct from the most recent run (needed for unlock checks).
    var lastExperiment: Experiment? = nil
    /// The result from the most recent run, or nil before first run.
    var latestResult: ExperimentResult? = nil
    /// True while the engine is computing a result.
    var isRunning: Bool = false

    // MARK: - Init

    init(organism: Organism, question: ResearchQuestion) {
        self.selectedOrganism = organism
        self.researchQuestion = question
    }

    // MARK: - Computed

    /// True when both IV and DV have been selected, enabling the Run button.
    var canRun: Bool {
        independentVariable != nil && dependentVariable != nil
    }

    // MARK: - Actions

    /// Compute the result without logging — call this before showing the animation.
    /// Logging happens later in PostExperimentView when the user taps "Log to Index".
    func prepareResult() {
        guard let iv = independentVariable, let dv = dependentVariable else { return }
        let experiment = Experiment(
            organismId: selectedOrganism.id,
            researchQuestion: researchQuestion,
            independentVariable: iv,
            dependentVariable: dv,
            controlledVariables: controlledVariables,
            hasControlGroup: hasControlGroup,
            sampleSize: sampleSize
        )
        lastExperiment = experiment
        latestResult = ExperimentEngine.generateResult(
            experiment: experiment,
            organism: selectedOrganism
        )
    }

    /// Build an Experiment from current selections, run it through the engine, and persist.
    func runExperiment(gameState: GameState) {
        prepareResult()
        guard let result = latestResult else { return }
        gameState.logExperiment(result, for: selectedOrganism.id)
        gameState.save()
    }

    /// Toggle a controlled variable on or off.
    func toggleControlledVariable(_ v: ControlledVariable) {
        if controlledVariables.contains(v) {
            controlledVariables.remove(v)
        } else {
            controlledVariables.insert(v)
        }
    }

    /// Clear all selections so the user can redesign from scratch.
    func reset() {
        independentVariable = nil
        dependentVariable = nil
        controlledVariables = []
        hasControlGroup = false
        sampleSize = 20
        lastExperiment = nil
        latestResult = nil
        isRunning = false
    }
}
