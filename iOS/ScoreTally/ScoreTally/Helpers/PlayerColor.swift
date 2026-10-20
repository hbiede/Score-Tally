//
// PlayerColor
// ScoreTally
//
// Created on 2026-10-09
//

import SwiftUI
import UIKit

/// A color from the palette players are drawn in, or any other color picked with the system color picker.
/// Raw values are stable so a player's chosen color can be stored.
enum PlayerColor: Hashable {
    case blue
    case orange
    case purple
    case teal
    case indigo
    case green
    // Pink reads close to the red used for losses, so it's only reached in big games
    case pink
    case brown
    /// A color from the system color picker
    case custom(Color.Resolved)

    /// The colors handed out to new players, in order
    static let palette: [PlayerColor] = [.blue, .orange, .purple, .teal, .indigo, .green, .pink, .brown]

    /// The color for the player who joined at `index`, cycling through the palette
    static func forJoinOrder(_ index: Int) -> PlayerColor {
        palette[index % palette.count]
    }

    /// The first palette color not in `used`, or the next in the cycle once they're all taken
    static func firstUnused(by used: [PlayerColor]) -> PlayerColor {
        palette.first { !used.contains($0) } ?? forJoinOrder(used.count)
    }

    /// The color's name, for VoiceOver
    var title: Text {
        switch self {
        case .blue:
            Text(.playerColorBlue)
        case .orange:
            Text(.playerColorOrange)
        case .purple:
            Text(.playerColorPurple)
        case .teal:
            Text(.playerColorTeal)
        case .indigo:
            Text(.playerColorIndigo)
        case .green:
            Text(.playerColorGreen)
        case .pink:
            Text(.playerColorPink)
        case .brown:
            Text(.playerColorBrown)
        case .custom(let color):
            // The system's own description, such as "dark blue"
            Text(UIColor(cgColor: color.cgColor).accessibilityName)
        }
    }

    var color: Color {
        switch self {
        case .blue:
            .blue
        case .orange:
            .orange
        case .purple:
            .purple
        case .teal:
            .teal
        case .pink:
            .pink
        case .indigo:
            .indigo
        case .brown:
            .brown
        case .green:
            .green
        case .custom(let color):
            Color(color)
        }
    }
}

extension PlayerColor: RawRepresentable {
    init?(rawValue: String) {
        if let color = Self.palette.first(where: { $0.rawValue == rawValue }) {
            self = color
        } else if let color = Color.Resolved(displayP3Hex: rawValue) {
            self = .custom(color)
        } else {
            return nil
        }
    }

    var rawValue: String {
        switch self {
        case .blue:
            "blue"
        case .orange:
            "orange"
        case .purple:
            "purple"
        case .teal:
            "teal"
        case .indigo:
            "indigo"
        case .green:
            "green"
        case .pink:
            "pink"
        case .brown:
            "brown"
        case .custom(let color):
            color.displayP3Hex
        }
    }
}

private extension Color.Resolved {
    private static let displayP3 = CGColorSpace(name: CGColorSpace.displayP3)!

    /// Reads a color written by `displayP3Hex`
    init?(displayP3Hex hex: String) {
        let digits = hex.dropFirst()
        guard hex.first == "#", digits.count == 6, digits.allSatisfy(\.isHexDigit),
              let value = UInt32(digits, radix: 16) else {
            return nil
        }
        self.init(colorSpace: .displayP3,
                  red: Float((value >> 16) & 0xFF) / 255,
                  green: Float((value >> 8) & 0xFF) / 255,
                  blue: Float(value & 0xFF) / 255)
    }

    /// The color as "#RRGGBB" in Display P3, which holds the vivid colors the system picker offers beyond sRGB
    var displayP3Hex: String {
        let components = cgColor.converted(to: Self.displayP3, intent: .defaultIntent, options: nil)?.components
            ?? [0, 0, 0]
        return "#" + components.prefix(3).map { component in
            String(format: "%02X", Int((min(max(component, 0), 1) * 255).rounded()))
        }.joined()
    }
}
