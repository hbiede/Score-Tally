//
// ScoreEntry
// ScoreTally
//
// Created on 2026-10-09
//

import Foundation
import SwiftData

/// The points one player scored in one round
@Model
final class ScoreEntry {
    var points = 0

    @Relationship(inverse: \Round.storedEntries)
    var round: Round?

    @Relationship(inverse: \Player.storedEntries)
    var player: Player?

    init(points: Int = 0) {
        self.points = points
    }

    /// Reading a property loads an entry SwiftData has only referenced, which it needs before deleting it
    func load() {
        _ = points
    }
}
