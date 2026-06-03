import SwiftUI

enum RetroTheme {
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let panel = Color(red: 1.00, green: 0.99, blue: 0.96)
    static let headerBlue = Color(red: 0.86, green: 0.92, blue: 1.00)
    static let headerMint = Color(red: 0.89, green: 0.97, blue: 0.92)
    static let blue = Color(red: 0.18, green: 0.38, blue: 0.70)
    static let mint = Color(red: 0.16, green: 0.55, blue: 0.36)
    static let ink = Color(red: 0.03, green: 0.10, blue: 0.23)
    static let grayLine = Color(red: 0.48, green: 0.56, blue: 0.66)
    static let shadow = Color(red: 0.46, green: 0.50, blue: 0.58).opacity(0.55)
    static let highlight = Color.white.opacity(0.95)
    static let lowlight = Color(red: 0.30, green: 0.36, blue: 0.44).opacity(0.75)
    static let controlSurface = Color.white.opacity(0.75)
    static let subtleSurface = Color.white.opacity(0.5)
    static let inactiveSegment = Color.white.opacity(0.35)
    static let headerHighlight = Color.white.opacity(0.82)
    static let disabledControlOpacity = 0.42

    enum PanelRole {
        case primary
        case secondary

        var accent: Color {
            switch self {
            case .primary:
                RetroTheme.blue
            case .secondary:
                RetroTheme.mint
            }
        }

        var headerTint: Color {
            switch self {
            case .primary:
                RetroTheme.headerBlue
            case .secondary:
                RetroTheme.headerMint
            }
        }
    }

    enum ButtonRole {
        case primary
        case secondary
        case neutral

        var foreground: Color {
            switch self {
            case .primary, .neutral:
                RetroTheme.blue
            case .secondary:
                Color(red: 0.14, green: 0.34, blue: 0.61)
            }
        }

        var backgroundColors: [Color] {
            switch self {
            case .primary:
                [
                    Color.white,
                    Color(red: 0.88, green: 0.93, blue: 0.99),
                    Color(red: 0.80, green: 0.88, blue: 0.96)
                ]
            case .secondary:
                [
                    Color.white,
                    Color(red: 0.91, green: 0.97, blue: 0.92),
                    Color(red: 0.84, green: 0.93, blue: 0.86)
                ]
            case .neutral:
                [
                    Color.white,
                    Color(red: 0.96, green: 0.96, blue: 0.93),
                    Color(red: 0.90, green: 0.91, blue: 0.88)
                ]
            }
        }
    }

    enum ButtonSize {
        case compact
        case regular
        case prominent

        var font: Font {
            switch self {
            case .compact:
                RetroFont.buttonCompact
            case .regular:
                RetroFont.button
            case .prominent:
                RetroFont.buttonProminent
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .compact:
                14
            case .regular:
                18
            case .prominent:
                34
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .compact:
                7
            case .regular:
                9
            case .prominent:
                13
            }
        }
    }

    enum Layout {
        static let screenHorizontalPadding: CGFloat = 22
        static let screenTopPadding: CGFloat = 14
        static let screenBottomPadding: CGFloat = 36
        static let panelSpacing: CGFloat = 18
        static let panelCornerRadius: CGFloat = 2
        static let panelHeaderMinHeight: CGFloat = 64
        static let panelHeaderHorizontalPadding: CGFloat = 16
        static let panelHeaderSpacing: CGFloat = 12
        static let panelIconFrame: CGFloat = 32
        static let panelIconGlyph: CGFloat = 24
        static let panelBadgeWidth: CGFloat = 28
        static let panelBadgeHeight: CGFloat = 32
        static let panelChevronFrame: CGFloat = 30
        static let topStatusHeight: CGFloat = 44
        static let squareIconButtonWidth: CGFloat = 46
        static let squareIconButtonHeight: CGFloat = 42
        static let helpButtonSize: CGFloat = 32
        static let segmentedCornerRadius: CGFloat = 2
        static let meditationDialSize: CGFloat = 172
        static let meditationPanelSpacing: CGFloat = 20
        static let meditationPanelHorizontalPadding: CGFloat = 26
        static let meditationPanelVerticalPadding: CGFloat = 32
        static let meditationPrimaryButtonMinWidth: CGFloat = 190
        static let meditationCompactButtonMinWidth: CGFloat = 106
        static let meditationSecondaryControlSpacing: CGFloat = 10
        static let checkboxSize: CGFloat = 32
        static let durationEditorSpacing: CGFloat = 20
        static let durationEditorHorizontalPadding: CGFloat = 26
        static let durationEditorVerticalPadding: CGFloat = 32
    }

    enum Motion {
        static let panelToggle = Animation.snappy(duration: 0.2)
    }
}
