import SwiftUI

struct PrinciplePanel: View {
    let entry: PrincipleEntry
    let onPrevious: () -> Void
    let onNext: () -> Void
    @State private var isBodyExpanded = true

    init(
        entry: PrincipleEntry,
        onPrevious: @escaping () -> Void = {},
        onNext: @escaping () -> Void = {}
    ) {
        self.entry = entry
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                squareIconButton(
                    kind: .chevronLeft,
                    label: "Previous principle",
                    action: onPrevious
                )

                Spacer()

                Text(entry.displayDate)
                    .font(RetroFont.principleDate)
                    .foregroundStyle(RetroTheme.mint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer()

                squareIconButton(
                    kind: .chevronRight,
                    label: "Next principle",
                    action: onNext
                )
            }

            RetroDivider()

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(entry.keyword)
                            .font(RetroFont.principleKeyword)
                            .foregroundStyle(RetroTheme.mint)

                        Text(entry.title)
                            .font(RetroFont.principleTitle)
                            .foregroundStyle(RetroTheme.ink)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    Button {
                        withAnimation(RetroTheme.Motion.panelToggle) {
                            isBodyExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isBodyExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(RetroTheme.ink)
                            .frame(
                                width: RetroTheme.Layout.panelChevronFrame,
                                height: RetroTheme.Layout.panelChevronFrame
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isBodyExpanded ? "Hide full principle" : "Show full principle")
                }

                if isBodyExpanded {
                    Text(entry.body)
                        .font(RetroFont.body)
                        .foregroundStyle(RetroTheme.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .onChange(of: entry.id) {
            isBodyExpanded = true
        }
    }

    private func squareIconButton(
        kind: PixelIcon.Kind,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            PixelIcon(kind: kind, size: 20)
                .frame(
                    width: RetroTheme.Layout.squareIconButtonWidth,
                    height: RetroTheme.Layout.squareIconButtonHeight
                )
                .background(RetroTheme.controlSurface)
                .beveledBorder(cornerRadius: RetroTheme.Layout.panelCornerRadius)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
