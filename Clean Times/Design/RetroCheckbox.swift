import SwiftUI

struct RetroCheckbox: View {
    @Binding var isChecked: Bool

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            ZStack {
                Rectangle()
                    .fill(RetroTheme.controlSurface)

                if isChecked {
                    RetroCheckboxMark()
                        .stroke(
                            RetroTheme.blue,
                            style: StrokeStyle(lineWidth: 3, lineCap: .square, lineJoin: .miter)
                        )
                        .padding(8)
                }
            }
            .frame(
                width: RetroTheme.Layout.checkboxSize,
                height: RetroTheme.Layout.checkboxSize
            )
            .beveledBorder(cornerRadius: RetroTheme.Layout.panelCornerRadius, shadowOffset: 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
}

private struct RetroCheckboxMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}
