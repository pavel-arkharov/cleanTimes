import SwiftUI

enum RetroFont {
    static func accent(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func digits(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced).monospacedDigit()
    }

    static let body = Font.body
    static let button = accent(17, weight: .medium)
    static let buttonCompact = accent(15, weight: .medium)
    static let buttonProminent = accent(22, weight: .semibold)
    static let chip = accent(16, weight: .medium)
    static let cleanTimeDetail = Font.system(size: 20, weight: .regular)
    static let cleanTimeUnit = Font.system(size: 34, weight: .regular)
    static let collapsedLabel = digits(20, weight: .medium)
    static let panelTitle = accent(19, weight: .semibold)
    static let principleDate = accent(20, weight: .semibold)
    static let principleKeyword = Font.system(size: 16, weight: .semibold)
    static let principleTitle = Font.system(size: 21, weight: .semibold)
    static let status = accent(20, weight: .medium)
    static let timer = digits(42, weight: .regular)
}
