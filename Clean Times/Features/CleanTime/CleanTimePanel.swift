import SwiftUI

struct CleanTimePanel: View {
    let cleanDate: Date
    let today: Date
    let onEdit: () -> Void

    @Environment(\.calendar) private var calendar

    private var snapshot: CleanTimeSnapshot {
        CleanTimeCalculator.snapshot(cleanDate: cleanDate, today: today, calendar: calendar)
    }

    var body: some View {
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

            RetroButton("edit", minWidth: 96, role: .secondary, action: onEdit)
                .accessibilityLabel("Edit clean date")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 34)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(snapshot.headline). \(snapshot.detail)")
    }
}
