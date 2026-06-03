import SwiftUI

struct PixelIcon: View {
    enum Kind {
        case battery
        case book
        case chevronLeft
        case chevronRight
        case clock
        case headphones
        case signal
        case wifi

        var systemName: String {
            switch self {
            case .battery:
                "battery.100"
            case .book:
                "book.closed"
            case .chevronLeft:
                "chevron.left"
            case .chevronRight:
                "chevron.right"
            case .clock:
                "clock"
            case .headphones:
                "headphones"
            case .signal:
                "cellularbars"
            case .wifi:
                "wifi"
            }
        }
    }

    let kind: Kind
    var size: CGFloat = 22

    var body: some View {
        Image(systemName: kind.systemName)
            .font(.system(size: size, weight: .semibold, design: .monospaced))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(RetroTheme.ink)
    }
}
