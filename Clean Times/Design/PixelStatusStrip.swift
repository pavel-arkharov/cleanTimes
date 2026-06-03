import SwiftUI

struct PixelStatusStrip: View {
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            HStack(spacing: 12) {
                Text(formatter.string(from: timeline.date))
                    .font(RetroFont.status)
                    .foregroundStyle(RetroTheme.ink)
                    .textCase(.uppercase)
                    .monospacedDigit()

                Spacer()

                HStack(spacing: 10) {
                    PixelIcon(kind: .signal, size: 20)
                    PixelIcon(kind: .wifi, size: 20)
                    PixelIcon(kind: .battery, size: 24)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Decorative status strip")
        }
        .frame(height: RetroTheme.Layout.topStatusHeight)
    }
}
