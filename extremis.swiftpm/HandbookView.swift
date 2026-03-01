import SwiftUI

/// Handbook tab — shows educational entries unlocked through experimentation.
struct HandbookView: View {
    var viewModel: IndexViewModel

    @State private var expandedIds: Set<String> = []

    private var unlocked: [HandbookEntry] { HandbookViewModel.unlockedEntries(for: viewModel.gameState) }
    private var locked: [HandbookEntry]   { HandbookViewModel.lockedEntries(for: viewModel.gameState) }

    var body: some View {
        VStack(spacing: 0) {
            customHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if unlocked.isEmpty {
                        emptyState
                    } else {
                        unlockedSection
                    }

                    if !locked.isEmpty {
                        lockedSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
        }
        .background(ColorTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ColorTheme.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(ColorTheme.border, lineWidth: 1)
                        }
                        .frame(width: 40, height: 40)
                    Image(systemName: "book.closed")
                        .font(.system(size: 16))
                        .foregroundStyle(ColorTheme.accent)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Handbook")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundStyle(ColorTheme.textPrimary)
                    Text("Concepts unlocked by experimenting.")
                        .font(.system(.caption2))
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("Unlocked")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(ColorTheme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(unlocked.count)")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(ColorTheme.textPrimary)
                    Text("of \(HandbookViewModel.allEntries.count)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(ColorTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(ColorTheme.border, lineWidth: 1)
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 12)
        .background(ColorTheme.background)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(ColorTheme.textSecondary.opacity(0.4))

            VStack(spacing: 6) {
                Text("Nothing yet")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(ColorTheme.textPrimary)
                Text("Run experiments to unlock concepts.\nEach good design reveals something new.")
                    .font(.system(.subheadline))
                    .foregroundStyle(ColorTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Unlocked Entries

    private var unlockedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Discovered")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ColorTheme.textSecondary)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(unlocked) { entry in
                    let isExpanded = expandedIds.contains(entry.id)
                    HandbookExpandableRow(entry: entry, isExpanded: isExpanded) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if isExpanded {
                                expandedIds.remove(entry.id)
                            } else {
                                expandedIds.insert(entry.id)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Locked Entries

    private var lockedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Locked")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ColorTheme.textSecondary.opacity(0.6))
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(locked) { entry in
                    HandbookLockedRow(entry: entry)
                }
            }
        }
    }
}

// MARK: - Expandable Row

private struct HandbookExpandableRow: View {
    var entry: HandbookEntry
    var isExpanded: Bool
    var onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(ColorTheme.accent.opacity(0.12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(ColorTheme.border, lineWidth: 1)
                            }
                            .frame(width: 44, height: 44)
                        Image(systemName: entry.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(ColorTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.title)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(ColorTheme.textPrimary)
                        Text(entry.summary)
                            .font(.system(.caption))
                            .foregroundStyle(ColorTheme.textSecondary)
                            .lineLimit(isExpanded ? nil : 1)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ColorTheme.textSecondary.opacity(0.4))
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Rectangle()
                    .fill(ColorTheme.border.opacity(0.6))
                    .frame(height: 1)
                    .padding(.horizontal, 14)

                Text(entry.body)
                    .font(.system(.subheadline))
                    .foregroundStyle(ColorTheme.textPrimary)
                    .lineSpacing(5)
                    .padding(14)

                HStack(spacing: 6) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 11))
                        .foregroundStyle(ColorTheme.accent.opacity(0.7))
                    Text(entry.unlockDescription)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(ColorTheme.textSecondary.opacity(0.7))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(ColorTheme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(ColorTheme.border, lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

// MARK: - Locked Row

private struct HandbookLockedRow: View {
    var entry: HandbookEntry

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(ColorTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(ColorTheme.border, lineWidth: 1)
                    }
                    .frame(width: 44, height: 44)
                Image(systemName: "lock")
                    .font(.system(size: 18))
                    .foregroundStyle(ColorTheme.textSecondary.opacity(0.35))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("???")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ColorTheme.textSecondary.opacity(0.4))
                Text(entry.unlockDescription)
                    .font(.system(.caption))
                    .foregroundStyle(ColorTheme.textSecondary.opacity(0.4))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(ColorTheme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(ColorTheme.border, lineWidth: 1)
                }
        }
    }
}
