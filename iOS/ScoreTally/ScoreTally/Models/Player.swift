//
// Player
// ScoreTally
//
// Created on 7/5/24
//

import Foundation
import SwiftData

@Model
final class Player {
    #Index<Player>([\.name, \.creationDate])

    var name = ""
    /// The total as last saved, which older versions of the app read and change directly.
    /// Read `total` instead, since `score` can miss points when devices sync conflicting changes.
    var score = 0
    /// The round points `score` included when this version of the app last changed it, or `nil` if it never has.
    /// It's saved alongside `score`, so the two always come from the same device.
    var recordedPoints: Int?
    var creationDate = Date.now
    /// The `PlayerColor` raw value, kept so colors don't shift when someone leaves
    var storedColor: String?

    @Relationship(inverse: \Game.storedPlayerList)
    var game: Game?

    @Relationship(deleteRule: .cascade)
    var storedEntries: [ScoreEntry]? = [ScoreEntry]()

    private var entryPoints: Int {
        (storedEntries ?? []).reduce(0) { $0 + $1.points }
    }

    /// Points no round accounts for, such as scores from before rounds were recorded
    /// or changes synced from older versions of the app
    var unrecordedPoints: Int {
        score - (recordedPoints ?? entryPoints)
    }

    /// The player's points. Entries from every device survive syncing even when one device's `score`
    /// overwrites another's, so this adds them up rather than trusting `score`.
    var total: Int {
        // `unrecordedPoints + entryPoints`, without adding up the entries twice
        guard let recordedPoints else {
            return score
        }
        return score - recordedPoints + entryPoints
    }

    /// Whether the player has ever had points, even if they're back to zero
    var hasScored: Bool {
        unrecordedPoints != 0 || (storedEntries ?? []).contains { $0.points != 0 }
    }

    /// The player's color, falling back to join order for players from older versions of the app
    var color: PlayerColor {
        storedColor.flatMap(PlayerColor.init(rawValue:))
            ?? PlayerColor.forJoinOrder(game?.players.firstIndex(of: self) ?? 0)
    }

    /// Up to two letters standing in for the player, such as "A" for "Adam" or "AB" for "Adam Brown"
    var initials: String {
        Self.initials(for: name)
    }

    /// Up to two letters standing in for `name`, for a player who hasn't been added yet
    static func initials(for name: String) -> String {
        if let components = initialsFormatter.personNameComponents(from: name) {
            let initials = initialsFormatter.string(from: components)
            if !initials.isEmpty {
                return initials
            }
        }
        return name.first.map { String($0).localizedUppercase } ?? ""
    }

    /// Shared since formatters are expensive to create
    private static let initialsFormatter: PersonNameComponentsFormatter = {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .abbreviated
        return formatter
    }()

    init(name: String, score: Int = 0) {
        self.name = name
        self.score = score
        self.creationDate = .now
    }

    /// Adds `value` to the score, recording it in the game's open round
    func increment(by value: Int = 1) {
        guard value != 0 else {
            return
        }
        guard let game else {
            score += value
            return
        }
        increment(by: value, in: game.currentRound())
    }

    func increment(by value: Int, in round: Round) {
        let unrecorded = unrecordedPoints
        entry(in: round).points += value
        recordedPoints = entryPoints
        score = unrecorded + entryPoints
    }

    /// Sets the player's points in `round`, or takes them out of it with `nil`, keeping their earlier points
    func setPoints(_ value: Int?, in round: Round) {
        guard round.points(for: self) != value else {
            return
        }
        let unrecorded = unrecordedPoints
        // Two devices can each add an entry for the same round, so all but one go
        let entries = (storedEntries ?? []).filter { $0.round == round }
        let removed = value == nil ? entries : Array(entries.dropFirst())
        for entry in removed {
            entry.load()
            modelContext?.delete(entry)
        }
        // Deleted entries stay in both lists until the context saves, so drop them now
        storedEntries?.removeAll { removed.contains($0) }
        round.storedEntries?.removeAll { removed.contains($0) }
        if let value {
            entry(in: round).points = value
        }
        recordedPoints = entryPoints
        score = unrecorded + entryPoints
    }

    /// Whether `resetScore()` would change anything
    var canResetScore: Bool {
        total != 0
    }

    /// Deletes the player and their entries in every round.
    /// SwiftData crashes deleting a related model it hasn't loaded yet ("Unexpected backing data for
    /// snapshot creation"), whether directly or by cascade, so each entry is loaded and deleted first.
    /// Rounds only this player has points in are deleted too, rather than left as empty rows.
    func delete() {
        guard let modelContext else {
            return
        }
        game?.keepColors()
        let entries = storedEntries ?? []
        let emptiedRounds = Set(entries.compactMap(\.round)).filter { round in
            (round.storedEntries ?? []).allSatisfy { $0.player == self }
        }
        for entry in entries {
            entry.load()
            modelContext.delete(entry)
        }
        storedEntries = []
        emptiedRounds.forEach { $0.delete() }
        modelContext.delete(self)
    }

    /// Zeroes the score, recording the change in the open round so the history still adds up
    func resetScore() {
        increment(by: -total)
    }

    private func entry(in round: Round) -> ScoreEntry {
        if let entry = storedEntries?.first(where: { $0.round == round }) {
            return entry
        }
        let entry = ScoreEntry()
        modelContext?.insert(entry)
        storedEntries?.append(entry)
        round.storedEntries?.append(entry)
        return entry
    }
}

extension Player: CustomStringConvertible {
    var description: String {
        "\(name): \(total)"
    }
}

extension Player: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(name): \(total)"
    }
}
