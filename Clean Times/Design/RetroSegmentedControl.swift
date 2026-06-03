import SwiftUI

struct RetroSegmentedControl<Value: Hashable>: View {
    let options: [Value]
    let selected: Value
    let isEnabled: Bool
    let title: (Value) -> String
    let onSelect: (Value) -> Void

    init(
        options: [Value],
        selected: Value,
        isEnabled: Bool = true,
        title: @escaping (Value) -> String,
        onSelect: @escaping (Value) -> Void
    ) {
        self.options = options
        self.selected = selected
        self.isEnabled = isEnabled
        self.title = title
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                RetroChip(
                    title: title(option),
                    isSelected: option == selected
                ) {
                    onSelect(option)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: RetroTheme.Layout.segmentedCornerRadius))
        .beveledBorder(
            cornerRadius: RetroTheme.Layout.segmentedCornerRadius,
            shadowOffset: 0
        )
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : RetroTheme.disabledControlOpacity)
        .accessibilityElement(children: .contain)
    }
}
