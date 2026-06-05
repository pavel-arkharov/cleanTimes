import SwiftUI

struct AboutSheet: View {
    let showsEditCleanTime: Bool
    let onEditCleanTime: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("CleanTimes")
                        .font(RetroFont.accent(24, weight: .semibold))
                        .foregroundStyle(RetroTheme.ink)

                    Text("CleanTimes is made by an addict in recovery and a member of NA, for people in any 12-step recovery path.")

                    Text("This app is not affiliated with, endorsed by, or sponsored by NA, AA, or any other fellowship. It is a personal recovery companion, not medical advice or treatment.")

                    if showsEditCleanTime {
                        RetroButton(
                            "Edit clean time",
                            minWidth: RetroTheme.Layout.editCleanTimeButtonMinWidth,
                            role: .secondary
                        ) {
                            onEditCleanTime()
                        }
                        .padding(.top, 10)
                    }
                }
                .font(RetroFont.body)
                .foregroundStyle(RetroTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .background(RetroTheme.paper)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
