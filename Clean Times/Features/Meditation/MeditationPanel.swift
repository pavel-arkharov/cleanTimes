import Combine
import SwiftUI

struct MeditationPanel: View {
    @Binding var durationSeconds: Double

    @AppStorage("meditationSoundsMuted") private var isMuted = false
    @StateObject private var timerModel: MeditationTimerModel
    @StateObject private var audioPlayer = MeditationAudioPlayer()
    @State private var showsDurationEditor = false

    private let options = [5, 10, 15, 20]
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(durationSeconds: Binding<Double>) {
        _durationSeconds = durationSeconds
        _timerModel = StateObject(
            wrappedValue: MeditationTimerModel(durationSeconds: durationSeconds.wrappedValue)
        )
    }

    private var selectedMinutes: Int {
        max(Int((timerModel.durationSeconds / 60).rounded()), 1)
    }

    var body: some View {
        VStack(spacing: RetroTheme.Layout.meditationPanelSpacing) {
            RetroTimerDial(
                text: timerModel.formattedRemaining,
                accessibilityLabel: timerModel.timerAccessibilityLabel
            )

            RetroButton(
                timerModel.primaryButtonTitle,
                minWidth: RetroTheme.Layout.meditationPrimaryButtonMinWidth,
                role: .primary,
                size: .prominent,
                action: performPrimaryAction
            )
            .accessibilityLabel(timerModel.primaryAccessibilityLabel)

            RetroSegmentedControl(
                options: options,
                selected: selectedMinutes,
                isEnabled: timerModel.canEditDuration,
                title: { "\($0)" }
            ) { minutes in
                setDuration(minutes: minutes)
            }

            HStack(spacing: RetroTheme.Layout.meditationSecondaryControlSpacing) {
                RetroButton(
                    secondaryButtonTitle,
                    minWidth: RetroTheme.Layout.meditationCompactButtonMinWidth,
                    role: .secondary,
                    size: .compact,
                    action: performSecondaryAction
                )
                .accessibilityLabel(secondaryAccessibilityLabel)

                RetroCheckbox(isChecked: $isMuted)
                    .accessibilityLabel("Mute meditation sounds")
                    .accessibilityValue(isMuted ? "Muted" : "Unmuted")
            }
        }
        .padding(.horizontal, RetroTheme.Layout.meditationPanelHorizontalPadding)
        .padding(.vertical, RetroTheme.Layout.meditationPanelVerticalPadding)
        .onAppear {
            synchronizeStoredDuration()
            updateWakeLock()
        }
        .onDisappear {
            MeditationWakeLock.setActive(false)
        }
        .onReceive(ticker) { _ in
            playCues(timerModel.tick())
        }
        .onChange(of: timerModel.state) {
            updateWakeLock()
        }
        .onChange(of: durationSeconds) { _, newValue in
            guard timerModel.canEditDuration else { return }
            timerModel.setDuration(seconds: newValue)
            synchronizeStoredDuration()
        }
        .onChange(of: isMuted) { _, newValue in
            if newValue {
                audioPlayer.stopAll()
            }
        }
        .sheet(isPresented: $showsDurationEditor) {
            MeditationDurationEditor(durationSeconds: timerModel.durationSeconds) { minutes in
                setDuration(minutes: minutes)
            }
        }
    }

    private var secondaryButtonTitle: String {
        timerModel.showsResetControl ? "reset" : "edit time"
    }

    private var secondaryAccessibilityLabel: String {
        timerModel.showsResetControl ? "Reset meditation timer" : "Edit meditation time"
    }

    private func performPrimaryAction() {
        playCues(timerModel.performPrimaryAction())
    }

    private func performSecondaryAction() {
        if timerModel.showsResetControl {
            timerModel.reset()
        } else {
            showsDurationEditor = true
        }
    }

    private func setDuration(minutes: Int) {
        timerModel.setDuration(seconds: Double(minutes * 60))
        durationSeconds = timerModel.durationSeconds
    }

    private func synchronizeStoredDuration() {
        timerModel.setDuration(seconds: durationSeconds)
        durationSeconds = timerModel.durationSeconds
    }

    private func playCues(_ cues: [MeditationTimerModel.Cue]) {
        guard !isMuted else { return }
        audioPlayer.play(cues)
    }

    private func updateWakeLock() {
        MeditationWakeLock.setActive(timerModel.state == .running)
    }
}
