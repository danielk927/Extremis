import SwiftUI

/// First-run three-page onboarding presented as a full-screen cover.
struct OnboardingView: View {
    var gameState: GameState

    @State private var page = 0
    @State private var pulsing = false

    var body: some View {
        ZStack {
            ColorTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $page) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 420)

                Spacer()

                pageDots
                    .padding(.bottom, 28)

                ctaButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Page dots

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i == page
                          ? ColorTheme.accent
                          : ColorTheme.border)
                    .frame(width: i == page ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
            }
        }
    }

    // MARK: - CTA button

    private var ctaButton: some View {
        Button {
            if page < 2 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { page += 1 }
            } else {
                gameState.hasSeenOnboarding = true
                gameState.save()
            }
        } label: {
            Text(page < 2 ? "Next" : "Start Exploring")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ColorTheme.accent)
                )
        }
    }

    // MARK: - Page 1 — Pulsing flask

    private var page1: some View {
        VStack(spacing: 28) {
            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(ColorTheme.accent.opacity(0.08))
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulsing ? 1.15 : 1.0)
                // Inner glow
                Circle()
                    .fill(ColorTheme.accent.opacity(0.14))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulsing ? 1.08 : 1.0)
                Image(systemName: "flask")
                    .font(.system(size: 64))
                    .foregroundStyle(ColorTheme.accent)
                    .scaleEffect(pulsing ? 1.06 : 1.0)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
                ) { pulsing = true }
            }

            VStack(spacing: 10) {
                Text("Extremis")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(ColorTheme.textPrimary)
                Text("Learn to think like a scientist.")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(ColorTheme.accent)
            }

            Text("Design experiments. Discover how organisms survive extreme conditions. Build your Species Index.")
                .font(.system(.body))
                .foregroundStyle(ColorTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Page 2 — Organism card previews

    private var page2: some View {
        let coralColor = OrganismDatabase.allOrganisms
            .first(where: { $0.commonName == "Reef Coral" })?.signatureColorValue
            ?? ColorTheme.accent
        return VStack(spacing: 28) {
            HStack(spacing: 14) {
                miniOrganismCard(color: ColorTheme.accent,        label: "Trout")
                miniOrganismCard(color: ColorTheme.textSecondary, label: "Gecko")
                miniOrganismCard(color: coralColor,               label: "Coral")
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                Text("Collect & Discover")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(ColorTheme.textPrimary)
            }

            Text("Each organism has hidden biological secrets. Your experimental design determines what you uncover.")
                .font(.system(.body))
                .foregroundStyle(ColorTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func miniOrganismCard(color: Color, label: String) -> some View {
        let barWidths: [CGFloat] = [38, 26, 34]
        return VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.12))
                .frame(height: 100)
                .overlay(
                    VStack(spacing: 8) {
                        Circle()
                            .fill(color.opacity(0.65))
                            .frame(width: 30, height: 30)
                        VStack(spacing: 4) {
                            ForEach(0..<3) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(color.opacity(0.28))
                                    .frame(width: barWidths[i], height: 4)
                            }
                        }
                    }
                )
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    // MARK: - Page 3 — Chart quality comparison

    private var page3: some View {
        VStack(spacing: 28) {
            HStack(spacing: 16) {
                miniChart(isClean: false, label: "★★")
                miniChart(isClean: true,  label: "★★★★★")
            }
            .padding(.horizontal, 20)

            Text("Better Science,\nBetter Data")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(ColorTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text("Choose your variables. Control your conditions. The quality of your results depends on you.")
                .font(.system(.body))
                .foregroundStyle(ColorTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func miniChart(isClean: Bool, label: String) -> some View {
        let dotColor  = isClean ? ColorTheme.accent : ColorTheme.textSecondary
        let lineColor = ColorTheme.accent

        return VStack(spacing: 8) {
            Canvas { ctx, size in
                let r: CGFloat = isClean ? 3.5 : 3.0
                let pts: [CGPoint]

                if isClean {
                    // Tight sigmoid survival curve
                    pts = stride(from: 0.0, through: 1.0, by: 0.09).map { t in
                        let y = 1.0 / (1.0 + exp(-9.0 * (t - 0.55)))
                        return CGPoint(x: t * size.width,
                                       y: (1.0 - y) * size.height)
                    }
                    // Trend line
                    var line = Path()
                    line.move(to: pts[0])
                    pts.dropFirst().forEach { line.addLine(to: $0) }
                    ctx.stroke(line,
                               with: .color(lineColor.opacity(0.25)),
                               lineWidth: 1.5)
                } else {
                    // Scattered points with no clear shape
                    pts = [
                        CGPoint(x: 0.05 * size.width, y: 0.20 * size.height),
                        CGPoint(x: 0.15 * size.width, y: 0.75 * size.height),
                        CGPoint(x: 0.25 * size.width, y: 0.32 * size.height),
                        CGPoint(x: 0.35 * size.width, y: 0.85 * size.height),
                        CGPoint(x: 0.45 * size.width, y: 0.42 * size.height),
                        CGPoint(x: 0.55 * size.width, y: 0.62 * size.height),
                        CGPoint(x: 0.65 * size.width, y: 0.22 * size.height),
                        CGPoint(x: 0.75 * size.width, y: 0.70 * size.height),
                        CGPoint(x: 0.85 * size.width, y: 0.48 * size.height),
                        CGPoint(x: 0.95 * size.width, y: 0.82 * size.height),
                    ]
                }

                for pt in pts {
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: pt.x - r, y: pt.y - r,
                            width: r * 2, height: r * 2
                        )),
                        with: .color(dotColor.opacity(0.85))
                    )
                }
            }
            .frame(height: 80)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(ColorTheme.cardBackground)
            )

            Text(label)
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundStyle(dotColor)
        }
    }
}
