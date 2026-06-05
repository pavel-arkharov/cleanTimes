import SwiftUI

enum HomePanel: Hashable {
    case cleanTime
    case principle
    case meditation
}

struct HomeView: View {
    @AppStorage("isCleanDateSet") private var isCleanDateSet = false
    @AppStorage("cleanDate") private var cleanDateInterval = Date().timeIntervalSinceReferenceDate
    @AppStorage("meditationDefaultDurationSeconds") private var meditationDefaultDurationSeconds = 900.0

    @Environment(\.calendar) private var calendar
    @State private var expandedPanel: HomePanel?
    @State private var showsAbout = false
    @State private var showsCleanDateEditor = false
    @State private var opensCleanDateEditorAfterAbout = false
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
        ZStack(alignment: .bottomTrailing) {
            RetroTheme.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: RetroTheme.Layout.panelSpacing) {
                    RetroPanel(
                        title: "Clean Time",
                        icon: .clock,
                        role: .primary,
                        collapsedLabel: isCleanDateSet ? cleanSnapshot.collapsedLabel : nil,
                        isExpanded: expandedPanel == .cleanTime,
                        onTap: { toggle(.cleanTime) }
                    ) {
                        CleanTimePanel(
                            cleanDate: cleanDate,
                            today: .now,
                            isCleanDateSet: isCleanDateSet
                        ) {
                            showsCleanDateEditor = true
                        }
                    }

                    RetroPanel(
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
                .padding(.bottom, RetroTheme.Layout.screenBottomPaddingWithControls)
            }

            helpButton
                .padding(.trailing, RetroTheme.Layout.screenHorizontalPadding)
                .padding(.bottom, RetroTheme.Layout.floatingControlsBottomPadding)
        }
        .onAppear {
            migrateLegacyCleanDateStateIfNeeded()
            currentPrincipleEntry = principleRepository.entry(for: .now, calendar: calendar)
        }
        .sheet(isPresented: $showsAbout, onDismiss: presentCleanDateEditorIfNeeded) {
            AboutSheet(showsEditCleanTime: isCleanDateSet) {
                opensCleanDateEditorAfterAbout = true
                showsAbout = false
            }
        }
        .sheet(isPresented: $showsCleanDateEditor) {
            CleanDateEditor(currentCleanDate: cleanDate) { newDate in
                cleanDateInterval = newDate.timeIntervalSinceReferenceDate
                isCleanDateSet = true
            }
        }
    }

    private var helpButton: some View {
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

    private func presentCleanDateEditorIfNeeded() {
        guard opensCleanDateEditorAfterAbout else {
            return
        }

        opensCleanDateEditorAfterAbout = false
        showsCleanDateEditor = true
    }

    private func migrateLegacyCleanDateStateIfNeeded() {
        guard !isCleanDateSet else {
            return
        }

        isCleanDateSet = UserDefaults.standard.object(forKey: "cleanDate") != nil
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
