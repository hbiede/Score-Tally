//
// Round
// ScoreTally
//
// Created on 2026-10-09
//

import Foundation
import SwiftData

/// A round of play. Points collect in the open round until "Score Round" completes it.
@Model
final class Round {
    #Index<Round>([\.createdDate])

    var createdDate = Date.now
    var isComplete = false

    @Relationship(inverse: \Game.storedRounds)
    var game: Game?

    @Relationship(deleteRule: .cascade)
    var storedEntries: [ScoreEntry]? = [ScoreEntry]()

    init(createdDate: Date = .now) {
        self.createdDate = createdDate
    }

    /// Reading a property loads a round SwiftData has only referenced, which it needs before deleting it
    func load() {
        _ = isComplete
    }

    /// Deletes the round, loading and deleting its entries first for the same reason as `Player.delete()`
    func delete() {
        guard let modelContext else {
            return
        }
        load()
        for entry in storedEntries ?? [] {
            entry.load()
            modelContext.delete(entry)
        }
        storedEntries = []
        modelContext.delete(self)
    }

    /// The points `player` scored this round, or `nil` if they have no entry.
    /// Two devices can each add an entry for the same player before syncing, so this adds them all up.
    func points(for player: Player) -> Int? {
        let entries = (storedEntries ?? []).filter { $0.player == player }
        return entries.isEmpty ? nil : entries.reduce(0) { $0 + $1.points }
    }
}
