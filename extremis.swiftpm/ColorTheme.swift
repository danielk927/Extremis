import SwiftUI

/// Centralized color system for the Extremis app — light Notion/Health-style palette.
enum ColorTheme {

    // MARK: - Core Palette (7 colors)

    static let background     = Color(hex: "FFFFFF")
    static let cardBackground = Color(hex: "F5F5F5")
    static let accent         = Color(hex: "95BB72")
    static let textPrimary    = Color(hex: "1A1A1A")
    static let textSecondary  = Color(hex: "6B7280")
    static let star           = Color(hex: "D4A84B")
    static let border         = Color(hex: "D1D5DB")

    // MARK: - Semantic Aliases

    static let highConfidence = Color(hex: "D4A84B")  // star fill
    static let lowConfidence  = Color(hex: "D1D5DB")  // empty star / border
}
