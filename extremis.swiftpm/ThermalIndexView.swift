import SwiftUI

/// The app's main screen — Species Index — with a custom floating tab bar.
struct ThermalIndexView: View {
    var viewModel: IndexViewModel

    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    NavigationStack(path: Binding(
                        get: { viewModel.navigationPath },
                        set: { viewModel.navigationPath = $0 }
                    )) {
                        IndexTabContent(viewModel: viewModel)
                            .navigationDestination(for: UUID.self) { organismId in
                                if let organism = OrganismDatabase.organism(for: organismId) {
                                    OrganismDetailView(organism: organism, viewModel: viewModel)
                                }
                            }
                    }
                case 1:
                    NavigationStack {
                        ChallengesListView(viewModel: viewModel)
                    }
                default:
                    NavigationStack {
                        HandbookView(viewModel: viewModel)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating tab bar
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
        }
        .background(ColorTheme.background.ignoresSafeArea())
    }
}

// MARK: - Custom Floating Tab Bar

private struct CustomTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(label: String, icon: String)] = [
        ("Species",    "square.grid.2x2"),
        ("Challenges", "medal"),
        ("Handbook",   "book.closed"),
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tabs.indices, id: \.self) { i in
                let isActive = selectedTab == i
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: 15, weight: .medium))
                        Text(tabs[i].label)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                    }
                    .foregroundStyle(isActive ? ColorTheme.accent : ColorTheme.textSecondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background {
                        if isActive {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(ColorTheme.accent.opacity(0.12))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 26)
                .fill(ColorTheme.background)
                .overlay {
                    RoundedRectangle(cornerRadius: 26)
                        .strokeBorder(ColorTheme.border, lineWidth: 1)
                }
        }
    }
}

// MARK: - Index Tab Content

/// 2-column scrollable grid of organism cards with a 2-row sticky header.
private struct IndexTabContent: View {
    var viewModel: IndexViewModel

    @State private var showAbout = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 2)

    var body: some View {
        VStack(spacing: 0) {
            customHeader

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(viewModel.sortedOrganisms) { organism in
                        let unlocked = viewModel.isUnlocked(organism)
                        let profile  = unlocked ? viewModel.profileFor(organism) : nil

                        if unlocked {
                            NavigationLink(value: organism.id) {
                                OrganismCardView(
                                    organism: organism,
                                    profile:  profile,
                                    isUnlocked: true
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            OrganismCardView(
                                organism: organism,
                                profile:  nil,
                                isUnlocked: false
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120) // room above tab bar
            }
        }
        .background(ColorTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAbout) {
            AboutSheet()
        }
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        VStack(spacing: 14) {
            // Row 1: branding + counter + action buttons
            HStack(spacing: 12) {
                // App icon + title
                HStack(spacing: 10) {
                    Image("ExtremisLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Extremis")
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .foregroundStyle(ColorTheme.textPrimary)
                        Text("Study how organisms survive extreme conditions.")
                            .font(.system(.caption2))
                            .foregroundStyle(ColorTheme.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Unlocked organism counter
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Unlocked")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(ColorTheme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(viewModel.unlockedOrganisms.count)")
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(ColorTheme.textPrimary)
                        Text("of \(OrganismDatabase.allOrganisms.count)")
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

                // Info button
                Button {
                    showAbout = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(ColorTheme.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(ColorTheme.border, lineWidth: 1)
                            }
                            .frame(width: 40, height: 40)
                        Image(systemName: "info.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(ColorTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("About Extremis")
            }

            // Row 2: subheader pills
            HStack(spacing: 8) {
                indexPill(icon: "thermometer", label: "Species")
                indexPill(icon: "sparkles", label: "New entries unlock with clean experiments")
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56) // below safe area
        .padding(.bottom, 12)
        .background(ColorTheme.background)
    }

    private func indexPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(ColorTheme.textSecondary)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(ColorTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(ColorTheme.background)
                .overlay {
                    Capsule()
                        .strokeBorder(ColorTheme.border, lineWidth: 1)
                }
        }
    }
}

// MARK: - About Sheet

private struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(ColorTheme.accent.opacity(0.10))
                                .frame(width: 64, height: 64)
                            Image(systemName: "flask")
                                .font(.system(size: 28))
                                .foregroundStyle(ColorTheme.accent)
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Extremis")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(ColorTheme.textPrimary)
                            Text("2026 Swift Student Challenge")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(ColorTheme.textSecondary)
                        }
                    }

                    Divider()
                        .background(ColorTheme.border)

                    aboutBlock(
                        heading: "What is Extremis?",
                        body: "Learn experimental design by studying how organisms survive extreme conditions — from scorching heat to UV radiation and drought."
                    )

                    aboutBlock(
                        heading: "Created by",
                        body: "Daniel Kim for the 2026 Apple Swift Student Challenge."
                    )

                    aboutBlock(
                        heading: "Inspiration",
                        body: "Inspired by research on thermal tolerance in C. elegans at the University of Chicago and Drosophila at UCLA, and work on ML models for metagenomics at Anto Biosciences."
                    )

                    aboutBlock(
                        heading: "Science",
                        body: "Thermal biology data reflects published scientific literature."
                    )
                }
                .padding(24)
            }
            .background(ColorTheme.background.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
            }
        }
    }

    private func aboutBlock(heading: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(heading.uppercased())
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(ColorTheme.textSecondary)
                .tracking(1.2)
            Text(body)
                .font(.system(.body))
                .foregroundStyle(ColorTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
