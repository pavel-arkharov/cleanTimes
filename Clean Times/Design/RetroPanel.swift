import SwiftUI

struct RetroPanel<ExpandedContent: View>: View {
    let number: Int
    let title: String
    let icon: PixelIcon.Kind
    let role: RetroTheme.PanelRole
    let collapsedLabel: String?
    let isExpanded: Bool
    let onTap: () -> Void
    @ViewBuilder let expandedContent: () -> ExpandedContent

    var body: some View {
        VStack(spacing: 0) {
            RetroPanelHeader(
                number: number,
                title: title,
                icon: icon,
                role: role,
                collapsedLabel: collapsedLabel,
                isExpanded: isExpanded,
                onTap: onTap
            )

            if isExpanded {
                Rectangle()
                    .fill(RetroTheme.blue.opacity(0.8))
                    .frame(height: 1)

                expandedContent()
                    .frame(maxWidth: .infinity)
                    .background(RetroTheme.panel)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(RetroTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: RetroTheme.Layout.panelCornerRadius))
        .beveledBorder(cornerRadius: RetroTheme.Layout.panelCornerRadius)
    }
}

struct RetroPanelHeader: View {
    let number: Int
    let title: String
    let icon: PixelIcon.Kind
    let role: RetroTheme.PanelRole
    let collapsedLabel: String?
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: RetroTheme.Layout.panelHeaderSpacing) {
                PixelIcon(kind: icon, size: RetroTheme.Layout.panelIconGlyph)
                    .frame(
                        width: RetroTheme.Layout.panelIconFrame,
                        height: RetroTheme.Layout.panelIconFrame
                    )

                Text("\(number)")
                    .font(RetroFont.panelBadge)
                    .foregroundStyle(.white)
                    .frame(
                        width: RetroTheme.Layout.panelBadgeWidth,
                        height: RetroTheme.Layout.panelBadgeHeight
                    )
                    .background(role.accent)
                    .beveledBorder(cornerRadius: RetroTheme.Layout.panelCornerRadius, shadowOffset: 0)

                Text(title)
                    .font(RetroFont.panelTitle)
                    .foregroundStyle(RetroTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 8)

                if let collapsedLabel {
                    Text(collapsedLabel)
                        .font(RetroFont.collapsedLabel)
                        .foregroundStyle(RetroTheme.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(RetroTheme.ink)
                    .frame(
                        width: RetroTheme.Layout.panelChevronFrame,
                        height: RetroTheme.Layout.panelChevronFrame
                    )
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, RetroTheme.Layout.panelHeaderHorizontalPadding)
            .frame(minHeight: RetroTheme.Layout.panelHeaderMinHeight)
            .background(
                LinearGradient(
                    colors: [role.headerTint.opacity(0.7), role.headerTint, RetroTheme.headerHighlight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
    }
}
