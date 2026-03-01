import SwiftUI
import Observation

// MARK: - HandbookEntry

struct HandbookEntry: Identifiable {
    var id: String
    var title: String
    var icon: String
    var accentColor: Color
    var summary: String
    var body: String
    /// Shown as a hint in the locked row explaining how to earn this entry.
    var unlockDescription: String
}

// MARK: - HandbookViewModel

@Observable
class HandbookViewModel {

    static let allEntries: [HandbookEntry] = [
        HandbookEntry(
            id: "independent_variables",
            title: "Independent Variable",
            icon: "arrow.up.arrow.down",
            accentColor: ColorTheme.accent,
            summary: "The one factor you deliberately manipulate.",
            body: """
The independent variable is the factor you choose to change between experimental groups. Everything else must stay constant — otherwise you won't know which change caused your result.

In thermal biology, temperature is almost always the independent variable. You expose groups of specimens to different temperatures (e.g., 25 °C, 30 °C, 35 °C, 40 °C) and measure how they respond at each level.

Choosing the wrong independent variable — like varying light level to study heat tolerance — produces data that can't answer your question. The scatter in your chart will reveal a random, structureless cloud instead of a clear trend.
""",
            unlockDescription: "Unlock by using Temperature as your independent variable."
        ),

        HandbookEntry(
            id: "dependent_variables",
            title: "Dependent Variable",
            icon: "chart.xyaxis.line",
            accentColor: ColorTheme.accent,
            summary: "What you observe or measure in response to your manipulation.",
            body: """
The dependent variable is what you record after changing the independent variable. It "depends" on what you did to the system.

The choice of measurement must match your research question. Measuring survival rate is ideal for CTMax — you want to know when the organism stops surviving. Measuring movement speed captures thermal optimum, where locomotor performance peaks.

Choosing a mismatched dependent variable introduces systematic bias. You may still detect a signal, but it will be shifted from the true value because the measurement doesn't directly reflect the process you're studying.
""",
            unlockDescription: "Unlock by choosing the correct measurement for your research question."
        ),

        HandbookEntry(
            id: "control_groups",
            title: "Control Group",
            icon: "equal.circle",
            accentColor: ColorTheme.accent,
            summary: "A baseline condition that lets you confirm cause and effect.",
            body: """
A control group is a set of specimens held at a standard baseline condition — in thermal experiments, typically room temperature (22 °C). It receives no treatment.

Without a control group, you cannot confirm that differences between your experimental groups are caused by the independent variable rather than by random variation or some undetected factor. The control provides the reference point every other measurement is compared against.

Including a control group is one of the highest-value improvements you can make to an experiment. It costs nothing and directly increases confidence in your findings.
""",
            unlockDescription: "Unlock by including a control group in any experiment."
        ),

        HandbookEntry(
            id: "controlled_variables",
            title: "Controlled Variables",
            icon: "slider.horizontal.3",
            accentColor: ColorTheme.accent,
            summary: "Factors held constant so they can't skew your results.",
            body: """
Controlled variables are all the factors you hold fixed across every experimental group. They're not what you're studying — but if left free to vary, they add noise that obscures the relationship you're trying to measure.

Some organisms have particular sensitivities. A humidity-sensitive organism will show erratic survival rates if humidity fluctuates, muddying the temperature signal. Controlling for humidity removes that source of variation.

You can discover an organism's sensitivities through repeated experimentation. When you notice that two experiments with identical designs produce wildly different results, suspect an uncontrolled variable.
""",
            unlockDescription: "Unlock by controlling a factor this organism is sensitive to."
        ),

        HandbookEntry(
            id: "sample_size",
            title: "Sample Size",
            icon: "person.3",
            accentColor: ColorTheme.accent,
            summary: "More specimens reduce the impact of individual variation.",
            body: """
Biological systems are noisy. Any individual organism may be unusually robust or unusually fragile due to genetic variation, developmental history, or chance. A small sample size lets these outliers dominate your result.

Statistical power is the ability to detect a real effect when one exists. More specimens means more power: the random differences between individuals average out, and the true trend emerges more clearly.

As a rule of thumb: 25 or more specimens provide solid statistical reliability. Fewer than 10 should be treated as a preliminary observation only. With very large samples (40+), even subtle effects become visible.
""",
            unlockDescription: "Unlock by running an experiment with 30 or more specimens."
        ),

        HandbookEntry(
            id: "confounding_variables",
            title: "Confounding Variables",
            icon: "exclamationmark.triangle",
            accentColor: ColorTheme.accent,
            summary: "Hidden factors that distort results by varying alongside your IV.",
            body: """
A confounding variable is an uncontrolled factor that correlates with your independent variable and independently affects your dependent variable. It creates a false or distorted picture of the relationship you're studying.

Suppose you raise temperature and also inadvertently allow humidity to rise (because warm air holds more moisture). If the organism is humidity-sensitive, you can't tell whether changes in the dependent variable were caused by temperature, humidity, or both.

Confounders are why large error margins and inconsistent results between repeated experiments are warning signs. They don't mean your experiment failed — they mean something else was changing that you didn't account for.
""",
            unlockDescription: "Unlock by missing a sensitive variable and getting a low-confidence result."
        ),

        HandbookEntry(
            id: "reproducibility",
            title: "Reproducibility",
            icon: "arrow.triangle.2.circlepath",
            accentColor: ColorTheme.accent,
            summary: "Consistent results across repeated experiments build reliable knowledge.",
            body: """
A single experiment is a data point. Science requires that findings be reproducible — that the same result emerges when the experiment is repeated under the same conditions, by the same or different researchers.

Reproducibility is the cornerstone of scientific credibility. A result that appears only once might be due to chance, equipment error, or an unusual batch of specimens. A result that holds across five independent experiments is far more trustworthy.

When you run the same experiment multiple times and refine your design, you reduce uncertainty and sharpen your estimate of the true value. Each additional run is a vote for or against your current hypothesis.
""",
            unlockDescription: "Unlock by running three or more experiments on the same organism."
        ),

        HandbookEntry(
            id: "experimental_design",
            title: "Experimental Design",
            icon: "checkmark.seal",
            accentColor: ColorTheme.accent,
            summary: "Combining all principles for publication-quality findings.",
            body: """
A well-designed experiment is rare and powerful. It requires the right independent variable, a dependent variable that directly captures the process under study, a proper control group, confounders controlled, and a sample large enough to yield reliable statistics.

When all five elements align, your error margin shrinks, your confidence rises, and your measured value converges on the true biological parameter. This is the goal of experimental design — not merely collecting data, but collecting the *right* data.

Excellent experimental design is a skill built through iteration. Each flaw in one experiment teaches you what to improve in the next. The feedback you receive after every run is a guide toward that standard.
""",
            unlockDescription: "Unlock by achieving ★★★★★ confidence on any experiment."
        ),
    ]

    static func unlockedEntries(for gameState: GameState) -> [HandbookEntry] {
        allEntries.filter { gameState.unlockedHandbookEntries.contains($0.id) }
    }

    static func lockedEntries(for gameState: GameState) -> [HandbookEntry] {
        allEntries.filter { !gameState.unlockedHandbookEntries.contains($0.id) }
    }
}
