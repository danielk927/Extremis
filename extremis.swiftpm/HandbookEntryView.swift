import SwiftUI

/// Full-text display for a single handbook entry.
struct HandbookEntryView: View {
    var entry: HandbookEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                heroCard
                bodyText
                discoveryNote
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(ColorTheme.background.ignoresSafeArea())
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(ColorTheme.accent.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: entry.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(ColorTheme.accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(ColorTheme.textPrimary)
                Text(entry.summary)
                    .font(.system(.subheadline))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(ColorTheme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Body

    private var bodyText: some View {
        Text(entry.body)
            .font(.system(.body))
            .foregroundStyle(ColorTheme.textPrimary)
            .lineSpacing(6)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(ColorTheme.cardBackground)
            )
    }

    // MARK: - Discovery Note

    private var discoveryNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb")
                .font(.system(size: 14))
                .foregroundStyle(ColorTheme.accent)
            Text(entry.unlockDescription)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(ColorTheme.textSecondary)
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ColorTheme.accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(ColorTheme.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
