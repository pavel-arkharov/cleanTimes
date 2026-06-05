import SwiftUI

struct CleanTimePanel: View {
    let cleanDate: Date
    let today: Date
    let isCleanDateSet: Bool
    let onEdit: () -> Void

    @Environment(\.calendar) private var calendar

    private var snapshot: CleanTimeSnapshot {
        CleanTimeCalculator.snapshot(cleanDate: cleanDate, today: today, calendar: calendar)
    }

    private var accessibilityLabelText: String {
        guard isCleanDateSet else {
            return "Clean time date has not been set"
        }

        return "\(snapshot.headline). \(snapshot.detail)"
    }

    var body: some View {
        content
        .padding(.horizontal, 20)
        .padding(.vertical, 34)
    }

    @ViewBuilder
    private var content: some View {
        if isCleanDateSet {
            VStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(snapshot.ordinalDay)")
                        .font(RetroFont.digits(86, weight: .light))
                        .foregroundStyle(RetroTheme.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .accessibilityHidden(true)

                    Text(snapshot.ordinalDay == 1 ? "day clean" : "days clean")
                        .font(RetroFont.cleanTimeUnit)
                        .foregroundStyle(RetroTheme.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Text(snapshot.detail)
                    .font(RetroFont.cleanTimeDetail)
                    .foregroundStyle(RetroTheme.ink.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .padding(.horizontal, 12)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabelText)
        } else {
            RetroButton(
                "Set clean time date",
                minWidth: RetroTheme.Layout.setCleanTimeButtonMinWidth,
                role: .primary,
                action: onEdit
            )
            .accessibilityLabel("Set clean time date")
        }
    }
}
