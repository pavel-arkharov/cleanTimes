import SwiftUI

struct PracticeCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: MeditationSessionStore

    @State private var visibleMonth = CalendarMonth()
    @State private var selectedDayKey = MeditationSession.localDayKey(
        for: .now,
        timezoneID: TimeZone.current.identifier
    )

    private let weekdayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var monthSessions: [MeditationSession] {
        store.completedSessions(year: visibleMonth.year, month: visibleMonth.month)
    }

    private var practiceDayMap: [String: PracticeDay] {
        MeditationPracticeSummary.dayMap(from: monthSessions)
    }

    private var monthTotal: TimeInterval {
        MeditationPracticeSummary.totalCreditedSeconds(in: monthSessions)
    }

    var body: some View {
        ZStack {
            RetroTheme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                VStack(spacing: 16) {
                    monthTotalRow
                    calendarGrid
                    selectedDayDetail
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(RetroTheme.panel)
            .beveledBorder(cornerRadius: RetroTheme.Layout.panelCornerRadius)
            .padding(.horizontal, 16)
            .padding(.vertical, 22)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            calendarIconButton(
                systemName: "chevron.left",
                accessibilityLabel: "Previous month"
            ) {
                moveMonth(by: -1)
            }

            VStack(spacing: 4) {
                Text("Practice Calendar")
                    .font(RetroFont.panelTitle)
                    .foregroundStyle(RetroTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(visibleMonth.title)
                    .font(RetroFont.accent(16, weight: .medium))
                    .foregroundStyle(RetroTheme.blue)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            calendarIconButton(
                systemName: "chevron.right",
                accessibilityLabel: "Next month"
            ) {
                moveMonth(by: 1)
            }

            calendarIconButton(
                systemName: "xmark",
                accessibilityLabel: "Close practice calendar",
                role: .secondary
            ) {
                dismiss()
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [
                    RetroTheme.headerBlue.opacity(0.72),
                    RetroTheme.headerBlue,
                    RetroTheme.headerHighlight
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RetroTheme.blue.opacity(0.8))
                .frame(height: 1)
        }
    }

    private var monthTotalRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Total completed time")
                .font(RetroFont.accent(14, weight: .medium))
                .foregroundStyle(RetroTheme.ink)

            Spacer(minLength: 12)

            Text(durationText(monthTotal))
                .font(RetroFont.accent(16, weight: .semibold))
                .foregroundStyle(RetroTheme.blue)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(RetroFont.accent(11, weight: .semibold))
                    .foregroundStyle(RetroTheme.grayLine)
                    .frame(height: 22)
                    .frame(maxWidth: .infinity)
            }

            ForEach(visibleMonth.gridCells) { cell in
                if let day = cell.day, let dayKey = cell.localDayKey {
                    CalendarDayButton(
                        day: day,
                        dayKey: dayKey,
                        practiceDay: practiceDayMap[dayKey],
                        isSelected: selectedDayKey == dayKey,
                        isToday: dayKey == todayDayKey
                    ) {
                        selectedDayKey = dayKey
                    }
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var selectedDayDetail: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(selectedDayTitle)
                .font(RetroFont.accent(18, weight: .semibold))
                .foregroundStyle(RetroTheme.ink)

            Text(selectedDaySummary)
                .font(RetroFont.accent(15, weight: .regular))
                .foregroundStyle(RetroTheme.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RetroTheme.controlSurface)
        .beveledBorder(cornerRadius: RetroTheme.Layout.panelCornerRadius, shadowOffset: 0)
        .accessibilityElement(children: .combine)
    }

    private var selectedDayTitle: String {
        guard let date = date(from: selectedDayKey) else {
            return ""
        }

        return date.formatted(.dateTime.month(.wide).day())
    }

    private var selectedDaySummary: String {
        guard let practiceDay = practiceDayMap[selectedDayKey] else {
            return "No completed session"
        }

        let sessionLabel = practiceDay.completedSessionCount == 1 ? "session" : "sessions"
        return "\(practiceDay.completedSessionCount) \(sessionLabel), \(durationText(practiceDay.totalCreditedSeconds)) total"
    }

    private var todayDayKey: String {
        MeditationSession.localDayKey(for: .now, timezoneID: TimeZone.current.identifier)
    }

    private func moveMonth(by offset: Int) {
        visibleMonth = visibleMonth.advanced(by: offset)
        selectedDayKey = CalendarMonth.dayKey(
            year: visibleMonth.year,
            month: visibleMonth.month,
            day: 1
        )
    }

    private func calendarIconButton(
        systemName: String,
        accessibilityLabel: String,
        role: RetroTheme.ButtonRole = .neutral,
        action: @escaping () -> Void
    ) -> some View {
        RetroButton(minWidth: 18, role: role, size: .compact, action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(role.foreground)
                .frame(width: 18, height: 18)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private func date(from localDayKey: String) -> Date? {
        let parts = localDayKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }

        return Calendar.gregorianUTC.date(
            from: DateComponents(year: parts[0], month: parts[1], day: parts[2])
        )
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let roundedSeconds = max(Int(seconds.rounded()), 0)
        let hours = roundedSeconds / 3_600
        let minutes = (roundedSeconds % 3_600) / 60

        if hours > 0, minutes > 0 {
            return "\(hours) hr \(minutes) min"
        }

        if hours > 0 {
            return "\(hours) hr"
        }

        if minutes > 0 {
            return "\(minutes) min"
        }

        return "\(roundedSeconds) sec"
    }
}

private struct CalendarDayButton: View {
    let day: Int
    let dayKey: String
    let practiceDay: PracticeDay?
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    private var isPracticed: Bool {
        practiceDay != nil
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isPracticed {
                    // The final delivered enso circle asset is still pending.
                    // This deterministic fallback keeps the date-grid behavior shippable.
                    EnsoCircle(variant: day % 3)
                        .stroke(
                            isSelected ? Color(red: 0.14, green: 0.34, blue: 0.61) : RetroTheme.blue,
                            style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 36, height: 36)
                        .accessibilityHidden(true)
                }

                Text("\(day)")
                    .font(RetroFont.accent(17, weight: .semibold))
                    .foregroundStyle(RetroTheme.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(isSelected ? RetroTheme.headerMint.opacity(0.72) : Color.clear)
            .overlay {
                if isToday && !isSelected {
                    Rectangle()
                        .stroke(RetroTheme.grayLine, lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        guard let practiceDay else {
            return "\(day), no completed session"
        }

        return "\(day), practiced, \(durationText(practiceDay.totalCreditedSeconds))"
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let minutes = max(Int(seconds.rounded()) / 60, 0)
        if minutes > 0 {
            return "\(minutes) minutes"
        }

        return "\(max(Int(seconds.rounded()), 0)) seconds"
    }
}

private struct EnsoCircle: Shape {
    let variant: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch variant {
        case 1:
            path.move(to: point(29, 9, in: rect))
            path.addCurve(
                to: point(24, 33, in: rect),
                control1: point(36, 15, in: rect),
                control2: point(34, 28, in: rect)
            )
            path.addCurve(
                to: point(7, 20, in: rect),
                control1: point(15, 38, in: rect),
                control2: point(6, 30, in: rect)
            )
            path.addCurve(
                to: point(30, 9, in: rect),
                control1: point(8, 9, in: rect),
                control2: point(19, 3, in: rect)
            )

        case 2:
            path.move(to: point(11, 29, in: rect))
            path.addCurve(
                to: point(18, 7, in: rect),
                control1: point(4, 20, in: rect),
                control2: point(8, 10, in: rect)
            )
            path.addCurve(
                to: point(35, 22, in: rect),
                control1: point(29, 4, in: rect),
                control2: point(36, 11, in: rect)
            )
            path.addCurve(
                to: point(15, 33, in: rect),
                control1: point(34, 31, in: rect),
                control2: point(24, 36, in: rect)
            )

        default:
            path.move(to: point(31, 27, in: rect))
            path.addCurve(
                to: point(9, 27, in: rect),
                control1: point(27, 34, in: rect),
                control2: point(15, 35, in: rect)
            )
            path.addCurve(
                to: point(20, 6, in: rect),
                control1: point(3, 18, in: rect),
                control2: point(9, 7, in: rect)
            )
            path.addCurve(
                to: point(34, 23, in: rect),
                control1: point(31, 5, in: rect),
                control2: point(37, 14, in: rect)
            )
        }

        return path
    }

    private func point(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + (x / 40) * rect.width,
            y: rect.minY + (y / 40) * rect.height
        )
    }
}

#Preview("Practice Calendar") {
    PracticeCalendarView(store: MeditationSessionStore())
}
