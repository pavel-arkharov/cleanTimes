import SwiftUI

enum HomePanel: Hashable {
    case cleanTime
    case principle
    case meditation
}

struct HomeView: View {
    @AppStorage("cleanDate") private var cleanDateInterval = Date().timeIntervalSinceReferenceDate
    @AppStorage("meditationDefaultDurationSeconds") private var meditationDefaultDurationSeconds = 900.0

    @Environment(\.calendar) private var calendar
    @State private var expandedPanel: HomePanel?
    @State private var showsAbout = false
    @State private var showsCleanDateEditor = false
    @State private var currentPrincipleEntry = PrincipleEntry.sample

    private let principleRepository = PrincipleRepository()

    private var cleanDate: Date {
        Date(timeIntervalSinceReferenceDate: cleanDateInterval)
    }

    private var cleanSnapshot: CleanTimeSnapshot {
        CleanTimeCalculator.snapshot(cleanDate: cleanDate, calendar: calendar)
    }

    private var principlePanelTitle: String {
        "\(currentPrincipleEntry.displayDate) -- \(currentPrincipleEntry.keyword)"
    }

    var body: some View {
        ZStack {
            RetroTheme.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: RetroTheme.Layout.panelSpacing) {
                    topArea

                    RetroPanel(
                        number: 1,
                        title: "Clean Time",
                        icon: .clock,
                        role: .primary,
                        collapsedLabel: cleanSnapshot.collapsedLabel,
                        isExpanded: expandedPanel == .cleanTime,
                        onTap: { toggle(.cleanTime) }
                    ) {
                        CleanTimePanel(cleanDate: cleanDate, today: .now) {
                            showsCleanDateEditor = true
                        }
                    }

                    RetroPanel(
                        number: 2,
                        title: principlePanelTitle,
                        icon: .book,
                        role: .secondary,
                        collapsedLabel: nil,
                        isExpanded: expandedPanel == .principle,
                        onTap: { toggle(.principle) }
                    ) {
                        PrinciplePanel(
                            entry: currentPrincipleEntry,
                            onPrevious: {
                                currentPrincipleEntry = principleRepository.previous(
                                    before: currentPrincipleEntry
                                )
                            },
                            onNext: {
                                currentPrincipleEntry = principleRepository.next(
                                    after: currentPrincipleEntry
                                )
                            }
                        )
                    }

                    RetroPanel(
                        number: 3,
                        title: "Meditation",
                        icon: .headphones,
                        role: .primary,
                        collapsedLabel: nil,
                        isExpanded: expandedPanel == .meditation,
                        onTap: { toggle(.meditation) }
                    ) {
                        MeditationPanel(durationSeconds: $meditationDefaultDurationSeconds)
                    }
                }
                .padding(.horizontal, RetroTheme.Layout.screenHorizontalPadding)
                .padding(.top, RetroTheme.Layout.screenTopPadding)
                .padding(.bottom, RetroTheme.Layout.screenBottomPadding)
            }
        }
        .statusBarHidden(true)
        .onAppear {
            currentPrincipleEntry = principleRepository.entry(for: .now, calendar: calendar)
        }
        .sheet(isPresented: $showsAbout) {
            AboutSheet()
        }
        .sheet(isPresented: $showsCleanDateEditor) {
            CleanDateEditor(currentCleanDate: cleanDate) { newDate in
                cleanDateInterval = newDate.timeIntervalSinceReferenceDate
            }
        }
    }

    private var topArea: some View {
        ZStack(alignment: .topTrailing) {
            PixelStatusStrip()
                .padding(.trailing, 44)

            Button {
                showsAbout = true
            } label: {
                Text("?")
                    .font(RetroFont.accent(16, weight: .bold))
                    .foregroundStyle(RetroTheme.ink)
                    .frame(
                        width: RetroTheme.Layout.helpButtonSize,
                        height: RetroTheme.Layout.helpButtonSize
                    )
                    .background(RetroTheme.subtleSurface)
                    .beveledBorder(
                        cornerRadius: RetroTheme.Layout.panelCornerRadius,
                        shadowOffset: 1
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About CleanTimes")
        }
    }

    private func toggle(_ panel: HomePanel) {
        withAnimation(RetroTheme.Motion.panelToggle) {
            expandedPanel = expandedPanel == panel ? nil : panel
        }
    }
}

#Preview("Home") {
    HomeView()
}
