import SwiftUI

struct RetroChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RetroFont.chip)
                .foregroundStyle(RetroTheme.blue)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(isSelected ? RetroTheme.headerMint : RetroTheme.inactiveSegment)
                .overlay {
                    Rectangle()
                        .stroke(RetroTheme.grayLine.opacity(0.7), lineWidth: 1)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
