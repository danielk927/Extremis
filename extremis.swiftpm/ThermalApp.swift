import SwiftUI

@main
struct ExtremisApp: App {
    @State private var viewModel = IndexViewModel()

    var body: some Scene {
        WindowGroup {
            ThermalIndexView(viewModel: viewModel)
                .preferredColorScheme(.light)
                .fullScreenCover(
                    isPresented: Binding(
                        get: { !viewModel.gameState.hasSeenOnboarding },
                        set: { _ in }
                    )
                ) {
                    OnboardingView(gameState: viewModel.gameState)
                }
        }
    }
}
