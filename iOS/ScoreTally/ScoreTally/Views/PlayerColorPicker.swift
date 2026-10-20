//
// PlayerColorPicker
// ScoreTally
//
// Created on 2026-10-16
//

import SwiftUI
import UIKit

/// The palette as a grid of swatches beside a well that opens the system color picker,
/// with a check on the selected color
struct PlayerColorPicker: View {
    @Binding var selection: PlayerColor

    @ScaledMetric(relativeTo: .body) private var swatchSize = 36

    /// Room for the ring around the selected swatch
    private let ringInset: CGFloat = 3

    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(swatchSize + ringInset * 2), spacing: 12), count: 4)

        HStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(PlayerColor.palette, id: \.self) { color in
                    swatch(for: color)
                }
            }
            .fixedSize()

            Divider()
                .frame(height: swatchSize)

            customSwatch
        }
    }

    private func swatch(for color: PlayerColor) -> some View {
        let isSelected = color == selection

        return Button {
            selection = color
        } label: {
            Circle()
                .fill(color.color)
                .modifier(SelectionMarks(color: color.color, isSelected: isSelected, size: swatchSize, ringInset: ringInset))
        }
        // Borderless so each swatch takes its own taps inside a form row
        .buttonStyle(.borderless)
        .accessibilityLabel(color.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("color-\(color.rawValue)")
    }

    /// The system color well, showing the custom color once one is picked
    private var customSwatch: some View {
        let custom: Color.Resolved? = if case .custom(let color) = selection { color } else { nil }

        return SystemColorWell(color: custom,
                               title: String(localized: .playerColorLabel),
                               accessibilityLabel: String(localized: .playerColorCustom)) { color in
            selection = .custom(color)
        }
        .modifier(SelectionMarks(color: selection.color, isSelected: custom != nil, size: swatchSize, ringInset: ringInset))
    }
}

/// A check on the selected swatch, and a ring around it in its color
private struct SelectionMarks: ViewModifier {
    let color: Color
    let isSelected: Bool
    let size: CGFloat
    let ringInset: CGFloat

    @Environment(\.self) private var environment

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                        .foregroundStyle(color.resolve(in: environment).contrastingForeground)
                        // The marks are decoration, so taps go through to the color well beneath
                        .allowsHitTesting(false)
                }
            }
            .padding(ringInset)
            .overlay {
                Circle()
                    .strokeBorder(color, lineWidth: 2)
                    .opacity(isSelected ? 1 : 0)
                    .allowsHitTesting(false)
            }
    }
}

/// UIKit's color well, which presents the system color picker, sized to match the swatches.
/// SwiftUI's `ColorPicker` can't be resized or show an empty well while a palette color is picked.
private struct SystemColorWell: UIViewRepresentable {
    /// The well's color, or `nil` to show it empty
    let color: Color.Resolved?
    /// The title of the system color picker
    let title: String
    let accessibilityLabel: String
    /// Called as the color changes in the system picker, including while dragging
    let onChange: (Color.Resolved) -> Void

    func makeUIView(context: Context) -> UIColorWell {
        let well = UIColorWell()
        // Translucent players would blend into the rows behind them
        well.supportsAlpha = false
        well.accessibilityIdentifier = "color-custom"
        well.addTarget(context.coordinator, action: #selector(Coordinator.colorChanged(_:)), for: .valueChanged)
        return well
    }

    func updateUIView(_ well: UIColorWell, context: Context) {
        context.coordinator.onChange = onChange
        well.title = title
        well.accessibilityLabel = accessibilityLabel
        if color == nil {
            well.accessibilityTraits.remove(.selected)
        } else {
            well.accessibilityTraits.insert(.selected)
        }
        // Setting the color the picker just reported would fight the user's drag, so it's only set when it differs
        if well.selectedColor.map(Self.resolve) != color {
            well.selectedColor = color.map { UIColor(cgColor: $0.cgColor) }
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIColorWell, context: Context) -> CGSize? {
        // Fills its frame, unlike its fixed intrinsic size, so it can match the swatches
        proposal.replacingUnspecifiedDimensions()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange)
    }

    private static func resolve(_ color: UIColor) -> Color.Resolved {
        Color(uiColor: color).resolve(in: EnvironmentValues())
    }

    @MainActor
    final class Coordinator: NSObject {
        var onChange: (Color.Resolved) -> Void

        init(onChange: @escaping (Color.Resolved) -> Void) {
            self.onChange = onChange
        }

        @objc func colorChanged(_ well: UIColorWell) {
            guard let color = well.selectedColor else {
                return
            }
            onChange(SystemColorWell.resolve(color))
        }
    }
}

/// A player's avatar that opens the palette, for picking a color beside a name field
struct PlayerColorButton: View {
    @Binding var color: PlayerColor
    let name: String

    @State private var showingPicker = false
    @ScaledMetric(relativeTo: .body) private var avatarSize = 32

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            PlayerAvatar(initials: Player.initials(for: name.trimmed), color: color.color, size: avatarSize)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text(.playerColorLabel))
        .accessibilityValue(color.title)
        .popover(isPresented: $showingPicker) {
            PlayerColorPicker(selection: Binding {
                color
            } set: { newColor in
                color = newColor
                // Picking a color is the whole task, so the palette closes once one is chosen.
                // The system picker reports every change while it's open, and closing the palette would close it too.
                if case .custom = newColor {
                    return
                }
                showingPicker = false
            })
            .padding()
            .presentationCompactAdaptation(.popover)
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var color = PlayerColor.teal
    VStack(spacing: 32) {
        PlayerColorPicker(selection: $color)
        PlayerColorButton(color: $color, name: "Adam Brown")
    }
}
#endif
