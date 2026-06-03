import SwiftUI

struct BeveledBorderModifier: ViewModifier {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let shadowOffset: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(RetroTheme.grayLine, lineWidth: lineWidth)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(RetroTheme.highlight)
                    .frame(height: lineWidth)
                    .padding(.horizontal, max(cornerRadius, lineWidth))
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(RetroTheme.highlight)
                    .frame(width: lineWidth)
                    .padding(.vertical, max(cornerRadius, lineWidth))
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(RetroTheme.lowlight)
                    .frame(height: lineWidth)
                    .padding(.horizontal, max(cornerRadius, lineWidth))
            }
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(RetroTheme.lowlight)
                    .frame(width: lineWidth)
                    .padding(.vertical, max(cornerRadius, lineWidth))
            }
            .shadow(color: RetroTheme.shadow, radius: 0, x: shadowOffset, y: shadowOffset)
    }
}

extension View {
    func beveledBorder(
        cornerRadius: CGFloat = 2,
        lineWidth: CGFloat = 1,
        shadowOffset: CGFloat = 2
    ) -> some View {
        modifier(
            BeveledBorderModifier(
                cornerRadius: cornerRadius,
                lineWidth: lineWidth,
                shadowOffset: shadowOffset
            )
        )
    }
}
