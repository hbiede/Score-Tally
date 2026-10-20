//
// RoundTableCells
// ScoreTally
//
// Created on 2026-10-09
//

import SwiftData
import SwiftUI

extension Color {
    /// Marks the player in the lead
    static let crown = Color(red: 0.85, green: 0.65, blue: 0.13)
}

extension Int {
    /// Shared since formatters are expensive to create
    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.numberStyle = .ordinal
        return formatter
    }()

    /// The number as a place, such as "1st" for 1
    var ordinalFormatted: String {
        Self.ordinalFormatter.string(from: NSNumber(value: self)) ?? formatted()
    }
}

/// A circle in the player's color with their initials
struct PlayerAvatar: View {
    let initials: String
    let color: Color
    let size: CGFloat

    @Environment(\.self) private var environment

    init(player: Player, size: CGFloat) {
        self.init(initials: player.initials, color: player.color.color, size: size)
    }

    /// An avatar for a player who hasn't been added yet
    init(initials: String, color: Color, size: CGFloat) {
        self.initials = initials
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(color.resolve(in: environment).contrastingForeground)
            .minimumScaleFactor(0.5)
            .frame(width: size, height: size)
            .background(color, in: .circle)
            .accessibilityHidden(true)
    }
}

extension Color.Resolved {
    /// Whether white text keeps at least a 3:1 contrast ratio on this color.
    /// Resolved per environment, so bright colors like orange, teal and green switch to dark text
    /// while increased contrast's darker variants stay white.
    private var prefersWhiteText: Bool {
        // The resolved components are already linear sRGB, so they feed WCAG's relative luminance directly
        let luminance = 0.2126 * Double(red) + 0.7152 * Double(green) + 0.0722 * Double(blue)
        let whiteContrast = 1.05 / (luminance + 0.05)
        return whiteContrast >= 3
    }

    /// White or dark text, whichever reads better on this color
    var contrastingForeground: Color {
        prefersWhiteText ? .white : .black.opacity(0.8)
    }
}

/// The crown marking the player in the lead
struct CrownBadge: View {
    var body: some View {
        Image(systemName: "crown.fill")
            .font(.caption)
            .foregroundStyle(Color.crown)
    }
}

extension ShapeStyle where Self == AnyShapeStyle {
    /// A figure in the player's color while they lead, and plain otherwise
    static func leader(_ isLeader: Bool, color: Color) -> AnyShapeStyle {
        isLeader ? AnyShapeStyle(color) : AnyShapeStyle(.primary)
    }
}

/// A player's avatar and name, crowned while they lead
struct PlayerHeaderCell: View {
    let player: Player
    let isLeader: Bool
    /// Reports the name's natural width so columns can fit the longest name
    let onMeasureName: (CGFloat) -> Void

    @ScaledMetric(relativeTo: .headline) private var avatarSize = 36

    @State private var showingPicker = false

    var body: some View {
        let color = player.color.color

        Button(action: showEditColor) {
            VStack(spacing: 4) {
                // Every column keeps the crown's space so avatars line up
                CrownBadge()
                    .opacity(isLeader ? 1 : 0)
                PlayerAvatar(player: player, size: avatarSize)
                    .padding(3)
                    .overlay {
                        if isLeader {
                            Circle()
                                .stroke(color, lineWidth: 2)
                        }
                    }
                Text(player.name)
                    .font(.subheadline.weight(.semibold))
                    .background {
                        Text(player.name)
                            .font(.subheadline.weight(.semibold))
                            .fixedSize()
                            .hidden()
                            .onGeometryChange(for: CGFloat.self) { proxy in
                                proxy.size.width
                            } action: { width in
                                onMeasureName(width)
                            }
                    }
            }
        }
        .minimumScaleFactor(1)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(player.name)
        .accessibilityValue(isLeader ? String(localized: .leaderA11YValue) : "")
        .accessibilityHint(Text(.playerHeaderA11YHint))
        .popover(isPresented: $showingPicker) {
            // Picking a color is the whole task, so the palette closes once one is chosen
            PlayerColorPicker(selection: Binding {
                player.color
            } set: { newColor in
                player.storedColor = newColor.rawValue
                showingPicker = false
            })
            .padding()
            .presentationCompactAdaptation(.popover)
        }
    }

    private func showEditColor() {
        showingPicker = true
    }
}

/// A round's points with the player's total after it underneath
struct RoundCell: View {
    let points: Int?
    let runningTotal: Int
    let isBest: Bool
    let color: Color

    var body: some View {
        if let points {
            VStack(spacing: 1) {
                Text(points.formatted(.number))
                    .fontWeight(isBest ? .semibold : .regular)
                    .foregroundStyle(isBest ? AnyShapeStyle(color) : points.pointsStyle)
                Text(runningTotal.formatted(.number))
                    .font(.caption2)
                    .foregroundStyle(isBest ? AnyShapeStyle(color.opacity(0.8)) : AnyShapeStyle(.tertiary))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(isBest ? color.opacity(0.15) : .clear, in: .rect(cornerRadius: 8))
        } else {
            Dash()
        }
    }
}

/// A player's total, how close they are to the lead, and their place
struct TotalCell: View {
    let player: Player
    let rank: Int?
    /// From 0 for last to 1 for leading
    let lead: Double?
    let barWidth: CGFloat

    var body: some View {
        let color = player.color.color

        VStack(spacing: 4) {
            Text(player.total.formatted(.number))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.leader(rank == 0, color: color))
                .contentTransition(.numericText(value: Double(player.total)))
            Capsule()
                .fill(.quaternary)
                .frame(width: barWidth, height: 4)
                .overlay(alignment: .leading) {
                    if let lead {
                        Capsule()
                            .fill(color)
                            .frame(width: max(barWidth * lead, 4), height: 4)
                    }
                }
            if let rank {
                Text((rank + 1).ordinalFormatted)
                    .font(.caption.weight(rank == 0 ? .semibold : .regular))
                    .foregroundStyle(rank == 0 ? AnyShapeStyle(color) : AnyShapeStyle(.secondary))
            } else {
                Dash()
                    .font(.caption)
            }
        }
        .animation(.snappy, value: player.total)
    }
}

/// Marks a cell with no points
struct Dash: View {
    var body: some View {
        Text(verbatim: "—")
            .foregroundStyle(.tertiary)
    }
}

extension Int {
    /// Losses stand out and zeros recede
    var pointsStyle: AnyShapeStyle {
        if self < 0 {
            AnyShapeStyle(.red)
        } else if self == 0 {
            AnyShapeStyle(.secondary)
        } else {
            AnyShapeStyle(.primary)
        }
    }
}

/// The ways to look at a game's rounds
enum RoundViewMode: String, CaseIterable {
    case table
    case race
    case stats

    var title: LocalizedStringResource {
        switch self {
        case .table:
            .tableMode
        case .race:
            .raceMode
        case .stats:
            .statsMode
        }
    }
}

/// A round with its place in the game, which the editor and delete confirmation show
struct NumberedRound: Identifiable {
    let round: Round
    let number: Int

    var id: PersistentIdentifier {
        round.persistentModelID
    }
}

/// Shades a table row while it's pressed
struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(Color.primary.opacity(configuration.isPressed ? 0.06 : 0))
    }
}

/// A line along the top edge, for the in-progress round's dashed divider
struct TopEdge: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
    }
}
