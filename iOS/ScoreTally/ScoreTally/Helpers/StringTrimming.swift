//
// StringTrimming
// ScoreTally
//
// Created on 10/16/26
//

import Foundation

extension String {
    /// The string without leading or trailing whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
