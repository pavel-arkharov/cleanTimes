import SwiftUI

struct MeditationDurationEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var minutes: Int

    private let range: ClosedRange<Int>
    private let onSave: (Int) -> Void

    init(
        durationSeconds: TimeInterval,
        range: ClosedRange<Int> = 1...120,
        onSave: @escaping (Int) -> Void
    ) {
        let initialMinutes = Int((durationSeconds / 60).rounded())
        self.range = range
        self.onSave = onSave
        _minutes = State(initialValue: min(max(initialMinutes, range.lowerBound), range.upperBound))
    }

    var body: some View {
        ZStack {
            RetroTheme.paper.ignoresSafeArea()

            VStack(spacing: RetroTheme.Layout.durationEditorSpacing) {
                Text("edit time")
                    .font(RetroFont.panelTitle)
                    .foregroundStyle(RetroTheme.ink)

                Text("\(minutes) min")
                    .font(RetroFont.timer)
                    .foregroundStyle(RetroTheme.blue)
                    .monospacedDigit()
                    .accessibilityLabel("Meditation duration \(minutes) minutes")

                Stepper(
                    "Duration",
                    value: $minutes,
                    in: range,
                    step: 1
                )
                .font(RetroFont.body)
                .foregroundStyle(RetroTheme.ink)
                .labelsHidden()

                HStack(spacing: RetroTheme.Layout.panelHeaderSpacing) {
                    RetroButton(
                        "cancel",
                        minWidth: RetroTheme.Layout.meditationCompactButtonMinWidth,
                        role: .neutral,
                        size: .compact
                    ) {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel editing meditation duration")

                    RetroButton(
                        "save",
                        minWidth: RetroTheme.Layout.meditationCompactButtonMinWidth,
                        role: .secondary,
                        size: .compact
                    ) {
                        onSave(minutes)
                        dismiss()
                    }
                    .accessibilityLabel("Save meditation duration")
                }
            }
            .padding(.horizontal, RetroTheme.Layout.durationEditorHorizontalPadding)
            .padding(.vertical, RetroTheme.Layout.durationEditorVerticalPadding)
        }
    }
}
