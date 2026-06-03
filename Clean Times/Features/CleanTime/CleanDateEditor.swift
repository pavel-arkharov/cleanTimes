import SwiftUI

struct CleanDateEditor: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss

    let currentCleanDate: Date
    let today: Date
    let onSave: (Date) -> Void

    @State private var selectedDate: Date
    @State private var pendingDate: Date?
    @State private var showsConfirmation = false

    init(currentCleanDate: Date, today: Date = .now, onSave: @escaping (Date) -> Void) {
        self.currentCleanDate = currentCleanDate
        self.today = today
        self.onSave = onSave
        _selectedDate = State(initialValue: currentCleanDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Clean date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                } footer: {
                    Text("Clean time is counted from the start of this date.")
                }
            }
            .navigationTitle("Clean Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTapped()
                    }
                }
            }
            .alert("Confirm clean date", isPresented: $showsConfirmation, presenting: pendingDate) { date in
                Button("Save Date") {
                    commit(date)
                }

                Button("Cancel", role: .cancel) {
                    pendingDate = nil
                }
            } message: { date in
                Text(confirmationMessage(for: date))
            }
        }
    }

    private func saveTapped() {
        let normalizedDate = calendar.startOfDay(for: selectedDate)

        guard requiresConfirmation(for: normalizedDate) else {
            commit(normalizedDate)
            return
        }

        pendingDate = normalizedDate
        showsConfirmation = true
    }

    private func commit(_ date: Date) {
        onSave(calendar.startOfDay(for: date))
        dismiss()
    }

    private func requiresConfirmation(for date: Date) -> Bool {
        let todayStart = calendar.startOfDay(for: today)
        let currentStart = calendar.startOfDay(for: currentCleanDate)

        return date > todayStart || date > currentStart
    }

    private func confirmationMessage(for date: Date) -> String {
        let todayStart = calendar.startOfDay(for: today)

        if date > todayStart {
            return "This date is in the future. Save it anyway?"
        }

        return "This will lower the displayed clean time. Save this date?"
    }
}
