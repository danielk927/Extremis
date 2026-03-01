import SwiftUI

/// A row displaying one of the four discoverable thermal data fields.
struct DataFieldRow: View {
    /// Display name of the field (e.g. "Critical Thermal Maximum").
    var fieldName: String
    /// SF Symbol for the field icon.
    var sfSymbol: String
    /// Formatted discovered value string, or nil if undiscovered.
    var discoveredValue: String?
    /// Confidence rating (1–5) for the discovered value.
    var confidence: Int?
    /// Unit label (e.g. "°C").
    var unit: String
    /// Action when the user taps "Investigate".
    var onInvestigate: () -> Void

    var body: some View {
        if let discoveredValue, let confidence {
            discoveredRow(value: discoveredValue, confidence: confidence)
        } else {
            undiscoveredRow
        }
    }

    // MARK: - Discovered

    private func discoveredRow(value: String, confidence: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: sfSymbol)
                .font(.system(.title3))
                .foregroundStyle(ColorTheme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(fieldName)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(ColorTheme.textSecondary)

                Text("\(value)\(unit)")
                    .font(.system(.body, design: .monospaced, weight: .bold))
                    .foregroundStyle(ColorTheme.textPrimary)
            }

            Spacer()

            ConfidenceStarsView(rating: confidence, size: 12)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ColorTheme.cardBackground)
        )
    }

    // MARK: - Undiscovered

    private var undiscoveredRow: some View {
        HStack(spacing: 12) {
            Image(systemName: sfSymbol)
                .font(.system(.title3))
                .foregroundStyle(ColorTheme.textSecondary.opacity(0.5))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(fieldName)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(ColorTheme.textSecondary)

                Text("???")
                    .font(.system(.body, design: .monospaced, weight: .bold))
                    .foregroundStyle(ColorTheme.textSecondary.opacity(0.5))
            }

            Spacer()

            GlassPill(
                label: "Investigate",
                icon: "arrow.right",
                accentColor: ColorTheme.accent,
                action: onInvestigate
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ColorTheme.cardBackground)
        )
    }

    // MARK: - Value Formatting Helpers

    /// Format a temperature value with error margin.
    static func formatTemperature(_ value: Double, errorMargin: Double? = nil) -> String {
        if let error = errorMargin {
            return String(format: "%.1f°C ± %.1f", value, error)
        }
        return String(format: "%.1f", value)
    }

    /// Map a 0–1 scale value to a descriptive label.
    static func formatScaleValue(_ value: Double) -> String {
        switch value {
        case ..<0.1: return "None"
        case ..<0.3: return "Low"
        case ..<0.6: return "Moderate"
        case ..<0.8: return "High"
        default: return "Extreme"
        }
    }
}
