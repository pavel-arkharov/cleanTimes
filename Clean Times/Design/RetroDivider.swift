import SwiftUI

struct RetroDivider: View {
    var opacity: Double = 0.35

    var body: some View {
        Rectangle()
            .fill(RetroTheme.grayLine.opacity(opacity))
            .frame(height: 1)
    }
}
