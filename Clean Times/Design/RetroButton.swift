import SwiftUI

struct RetroButton<Label: View>: View {
    let minWidth: CGFloat?
    let role: RetroTheme.ButtonRole
    let size: RetroTheme.ButtonSize
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    init(
        minWidth: CGFloat? = nil,
        role: RetroTheme.ButtonRole = .primary,
        size: RetroTheme.ButtonSize = .regular,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.minWidth = minWidth
        self.role = role
        self.size = size
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            label()
                .font(size.font)
                .foregroundStyle(role.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(minWidth: minWidth)
                .padding(.horizontal, size.horizontalPadding)
                .padding(.vertical, size.verticalPadding)
                .background(buttonBackground)
                .beveledBorder(cornerRadius: 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var buttonBackground: some View {
        LinearGradient(
            colors: role.backgroundColors,
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension RetroButton where Label == Text {
    init(
        _ title: String,
        minWidth: CGFloat? = nil,
        role: RetroTheme.ButtonRole = .primary,
        size: RetroTheme.ButtonSize = .regular,
        action: @escaping () -> Void
    ) {
        self.init(minWidth: minWidth, role: role, size: size, action: action) {
            Text(title)
        }
    }
}
