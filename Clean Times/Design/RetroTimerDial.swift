import SwiftUI

struct RetroTimerDial: View {
    let text: String
    let accessibilityLabel: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(RetroTheme.grayLine.opacity(0.28), lineWidth: 5)
                .frame(
                    width: RetroTheme.Layout.meditationDialSize,
                    height: RetroTheme.Layout.meditationDialSize
                )

            Circle()
                .trim(from: 0, to: 0.76)
                .stroke(
                    RetroTheme.blue,
                    style: StrokeStyle(lineWidth: 7, lineCap: .square)
                )
                .rotationEffect(.degrees(112))
                .frame(
                    width: RetroTheme.Layout.meditationDialSize,
                    height: RetroTheme.Layout.meditationDialSize
                )

            Text(text)
                .font(RetroFont.timer)
                .foregroundStyle(RetroTheme.blue)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityLabel(accessibilityLabel)
    }
}
