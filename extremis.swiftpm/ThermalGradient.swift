import SwiftUI

/// Stub — thermal gradient removed in light-mode redesign.
struct ThermalGradient: View {
    var temperature: Double
    var range: ClosedRange<Double>

    var body: some View {
        Color.white.ignoresSafeArea()
    }
}
