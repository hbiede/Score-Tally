//
// Game
// ScoreTally
//
// Created on 7/5/24
//

import Foundation
import SwiftData

@Model
final class Game {
    #Index<Game>([\.name, \.createdDate])

    var name = ""
    var createdDate = Date.now
    var lowScoreWins = false

    @Relationship(deleteRule: .cascade)
    var storedPlayerList: [Player]? = [Player]()
    var players: [Player] {
        self.storedPlayerList?.sorted(by: { $0.creationDate < $1.creationDate }) ?? []
    }

    /// Whether the game has players, without sorting them like `players` does
    var hasPlayers: Bool {
        !(storedPlayerList ?? []).isEmpty
    }

    @Relationship(deleteRule: .cascade)
    var storedRounds: [Round]? = [Round]()
    /// Rounds in the order they were played. CloudKit doesn't keep to-many order, so this sorts by date.
    var rounds: [Round] {
        self.storedRounds?.sorted(by: { $0.createdDate < $1.createdDate }) ?? []
    }

    /// Whether the game has rounds, without sorting them like `rounds` does
    var hasRounds: Bool {
        !(storedRounds ?? []).isEmpty
    }

    /// The round still collecting points, if there is one
    var openRound: Round? {
        guard let last = rounds.last, !last.isComplete else {
            return nil
        }
        return last
    }

    /// The players from the highest score to the lowest, or the reverse in low-score games
    var playersByScore: [Player] {
        // Adds up each total once rather than on every comparison
        let players = storedPlayerList ?? []
        return zip(players, players.map(\.total))
            .sorted(by: lowScoreWins ? { $0.1 < $1.1 } : { $0.1 > $1.1 })
            .map(\.0)
    }

    var standings: Standings {
        Standings(scores: players.map(\.total), lowScoreWins: lowScoreWins)
    }

    /// The player in sole first place, if there is one
    var winner: Player? {
        let players = players
        let totals = players.map(\.total)
        guard let winningScore = Standings(scores: totals, lowScoreWins: lowScoreWins).winningScore else {
            return nil
        }
        return zip(players, totals).first { $0.1 == winningScore }?.0
    }

    init(name: String, lowScoreWins: Bool = false, createdDate: Date = .now) {
        self.name = name
        self.lowScoreWins = lowScoreWins
        self.createdDate = createdDate
    }

    /// Adds a player in `color`, or the next free color if it's `nil`
    @discardableResult
    func addPlayer(with name: String, score: Int = 0, color: PlayerColor? = nil) -> Player {
        let player = Player(name: name, score: score)
        player.storedColor = (color ?? nextColor).rawValue
        modelContext?.insert(player)
        storedPlayerList?.append(player)
        return player
    }

    /// The open round, starting a new one if the last round is complete
    func currentRound() -> Round {
        if let openRound {
            return openRound
        }
        let round = Round()
        modelContext?.insert(round)
        storedRounds?.append(round)
        return round
    }

    /// The first color nobody is using, or the next in the cycle once they're all taken
    var nextColor: PlayerColor {
        // A player deleted since the last save is still in the list
        let used = Set(players.filter { !$0.isDeleted }.map(\.color))
        return PlayerColor.palette.first { !used.contains($0) } ?? PlayerColor.forJoinOrder(players.count)
    }

    /// Stores every player's join-order color so removing someone doesn't shift everyone after them
    func keepColors() {
        for player in players where player.storedColor == nil {
            player.storedColor = player.color.rawValue
        }
    }

    /// Adds `points` to the open round and completes it.
    /// Every listed player gets an entry, so a zero shows they played the round.
    func completeRound(with points: some Sequence<(Player, Int)>) {
        let round = currentRound()
        mergeOpenRounds(into: round)
        for (player, value) in points {
            player.increment(by: value, in: round)
        }
        round.isComplete = true
    }

    /// Moves points from any other open round into `round`.
    /// Two devices can each start a round before syncing, which would otherwise leave one open for good.
    private func mergeOpenRounds(into round: Round) {
        for other in rounds where !other.isComplete && other != round {
            let entries = other.storedEntries ?? []
            other.storedEntries = []
            round.storedEntries?.append(contentsOf: entries)
            other.delete()
        }
    }

    /// Replaces the points in `round`, where `nil` takes a player out of it.
    /// A round nobody is left in is deleted rather than kept as an empty row.
    func setPoints(_ points: some Sequence<(Player, Int?)>, in round: Round) {
        for (player, value) in points {
            player.setPoints(value, in: round)
        }
        if (round.storedEntries ?? []).isEmpty {
            deleteRound(round)
        }
    }

    /// Deletes `round`, taking its points off everyone's totals
    func deleteRound(_ round: Round) {
        for player in players {
            player.setPoints(nil, in: round)
        }
        round.delete()
        // Like the entries, a deleted round stays in the list until the context saves
        storedRounds?.removeAll { $0 == round }
    }

    /// Whether `reset()` would change anything: some player has points or there's round history to clear
    var canReset: Bool {
        hasRounds || players.contains(where: \.canResetScore)
    }

    /// Deletes the game with its players and rounds, clearing out entries first like `Player.delete()`
    func delete() {
        guard let modelContext else {
            return
        }
        // Rounds go first so deleting the players doesn't also try to delete the rounds they emptied
        for round in storedRounds ?? [] {
            round.delete()
        }
        players.forEach { $0.delete() }
        modelContext.delete(self)
    }

    /// Zeroes every score and clears the round history
    func reset() {
        // Cascaded entries stay in the players' lists until the context saves, so drop them now
        for player in players {
            player.score = 0
            player.recordedPoints = 0
            player.storedEntries = []
        }
        for round in storedRounds ?? [] {
            round.delete()
        }
        storedRounds = []
    }

    /// Every player's rank in the full order. Views ranking several players should build this once.
    var ranking: Ranking {
        Ranking(players: players, lowScoreWins: lowScoreWins)
    }

    /// The player's total after each round, in order, starting from their earlier points.
    /// Rounds they skipped carry their total forward.
    func runningTotals(for player: Player) -> [Int] {
        runningTotals(for: player, in: rounds)
    }

    /// The player's running totals through `rounds`, which should be `self.rounds`,
    /// so a view showing several players sorts the rounds only once
    func runningTotals(for player: Player, in rounds: [Round]) -> [Int] {
        var total = player.unrecordedPoints
        return rounds.map { round in
            total += round.points(for: player) ?? 0
            return total
        }
    }

    /// A copy of the game with the same players, colors and round history
    @discardableResult
    func duplicate(named name: String) -> Game? {
        guard let modelContext else {
            return nil
        }
        let copy = Game(name: name, lowScoreWins: lowScoreWins)
        modelContext.insert(copy)

        var copies = [PersistentIdentifier: Player]()
        for player in players {
            let newPlayer = copy.addPlayer(with: player.name, score: player.unrecordedPoints)
            // Players made in one go can share a timestamp, so keep the original join order
            newPlayer.creationDate = player.creationDate
            newPlayer.storedColor = player.color.rawValue
            copies[player.persistentModelID] = newPlayer
        }

        for round in rounds {
            let newRound = Round(createdDate: round.createdDate)
            modelContext.insert(newRound)
            copy.storedRounds?.append(newRound)
            for entry in round.storedEntries ?? [] {
                if let player = entry.player, let newPlayer = copies[player.persistentModelID] {
                    newPlayer.increment(by: entry.points, in: newRound)
                }
            }
            newRound.isComplete = round.isComplete
        }
        return copy
    }
}

extension Game: CustomStringConvertible {
    var description: String {
        "\(name): \(players.map(\.description).formatted(.list(type: .and)))"
    }
}

extension Game: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(name): \(players.map { "(\($0.name): \($0.total))" }.formatted(.list(type: .and)))"
    }
}
