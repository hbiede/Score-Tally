//
// ScoreFieldText
// ScoreTally
//
// Created on 2026-10-29
//

import SwiftUI

// Score fields hold their text rather than a number, so a minus sign can be put in before any digits
// are typed, since the number pad has no minus key of its own
extension String {
    /// The text a score field starts with for `value`
    init(scoreEntry value: Int) {
        // Built by hand so the sign is a plain hyphen, without the direction marks some locales add
        self = (value < 0 ? "-" : "") + value.magnitude.formatted(.number.grouping(.never))
    }

    /// The whole number typed into a score field, or `nil` while it has no digits
    var scoreValue: Int? {
        let digits = compactMap(\.wholeNumberValue)
        guard !digits.isEmpty else { return nil }
        var magnitude = 0
        for digit in digits {
            let (shifted, overflow) = magnitude.multipliedReportingOverflow(by: 10)
            guard !overflow, shifted <= Int.max - digit else { return nil }
            magnitude = shifted + digit
        }
        return isNegativeScoreEntry ? -magnitude : magnitude
    }

    /// The text with only a leading minus sign and digits, dropping anything else a paste or hardware keyboard brings in
    var sanitizedScoreEntry: String {
        (isNegativeScoreEntry ? "-" : "") + filter(\.isWholeNumber)
    }

    /// The text with its minus sign added or taken away
    var togglingScoreSign: String {
        let digits = filter(\.isWholeNumber)
        return isNegativeScoreEntry ? digits : "-" + digits
    }

    private var isNegativeScoreEntry: Bool {
        contains { $0 == "-" || $0 == "\u{2212}" }
    }
}

extension View {
    /// Adds the keys the number pad lacks above it: one that flips the focused field between positive and negative,
    /// and Next or Done to move through the `count` fields
    func scoreEntryKeyboardToolbar(focusedIndex: FocusState<Int?>.Binding,
                                   count: Int,
                                   toggleSign: @escaping (Int) -> Void) -> some View {
        modifier(ScoreEntryKeyboardToolbar(focusedIndex: focusedIndex, count: count, toggleSign: toggleSign))
    }
}

// A modifier rather than a plain toolbar so it keeps the focus binding as a property, which has the bar
// update as focus moves between fields
private struct ScoreEntryKeyboardToolbar: ViewModifier {
    var focusedIndex: FocusState<Int?>.Binding
    let count: Int
    let toggleSign: (Int) -> Void

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    if let index = focusedIndex.wrappedValue {
                        toggleSign(index)
                    }
                } label: {
                    Label(.toggleScoreSignButton, systemImage: "plus.forwardslash.minus")
                }
                .accessibilityIdentifier("toggle-score-sign")
                Spacer()
                if let index = focusedIndex.wrappedValue, index < count - 1 {
                    Button(.nextFieldButton) {
                        focusedIndex.wrappedValue = index + 1
                    }
                    .accessibilityIdentifier("next-field")
                } else {
                    Button(.doneEditingButton) {
                        focusedIndex.wrappedValue = nil
                    }
                    .accessibilityIdentifier("done-editing")
                }
            }
        }
    }
}
