//
// GameStats
// ScoreTally
//
// Created on 2026-10-16
//

import SwiftData

/// Records and per-player figures drawn from a game's round history, keyed by player ID.
/// Figures about single rounds only count complete rounds, since an open one is still collecting points,
/// while figures about the lead follow the totals as they stand, open round included.
struct GameStats<PlayerID: Hashable> {
    /// One round's points by player, where a player without points sat it out
    struct RoundPoints {
        let points: [PlayerID: Int]
        let isComplete: Bool
    }

    /// A player's points in one complete round, or `nil` if they sat it out, and whether nobody beat them
    struct RoundResult: Equatable {
        let points: Int?
        let won: Bool
    }

    /// A figure a player holds, from the round it happened in (counting from 1)
    struct Record: Equatable {
        let player: PlayerID
        let value: Int
        let round: Int
    }

    /// The most places a player climbed, as zero-based ranks
    struct Climb: Equatable {
        let player: PlayerID
        let fromRank: Int
        let toRank: Int
    }

    /// The player whose round scores strayed least from their average
    struct Consistency: Equatable {
        let player: PlayerID
        /// The standard deviation of their round scores
        let deviation: Double
    }

    struct PlayerStats: Equatable {
        /// How they did in each complete round
        let results: [RoundResult]
        /// Complete rounds after which nobody's total beat theirs
        let roundsLed: Int
        /// The best points in one round, which is the lowest in a low-score game
        let best: Int?

        /// Their points in the complete rounds they played
        var points: [Int] {
            results.compactMap(\.points)
        }

        var roundsPlayed: Int {
            points.count
        }

        var average: Double? {
            let points = points
            return points.isEmpty ? nil : Double(points.reduce(0, +)) / Double(points.count)
        }

        /// Complete rounds where nobody beat their points
        var roundsWon: Int {
            results.count(where: \.won)
        }
    }

    let completeRounds: Int
    /// Times a new player took the lead outright, with ties leaving the lead where it was
    let leadChanges: Int
    /// How far first place is ahead of second, or `nil` with nobody to compare or before the game starts
    let leadMargin: Int?
    /// The average points a player scores in a round
    let averagePoints: Double?
    let bestRound: Record?
    /// The most rounds won in a row, at least two, with the round the streak started
    let hotStreak: Record?
    /// The widest gap between first and second place
    let biggestLead: Record?
    let biggestClimb: Climb?
    let mostConsistent: Consistency?
    /// The lowest and highest points anyone scored in a complete round
    let pointRange: ClosedRange<Int>?
    let players: [PlayerID: PlayerStats]

    /// Rounds a player needs before their consistency counts
    static var consistencyMinimumRounds: Int {
        3
    }

    /// Builds the stats for `players`, who are listed in join order so ties go the same way every time.
    /// Points from anyone not listed are left out, and a listed player without starting points starts at zero.
    init(players: [PlayerID], startingPoints: [PlayerID: Int], rounds: [RoundPoints], lowScoreWins: Bool) {
        // Everyone's totals before the first round, then after each one
        var checkpoints = [Dictionary(uniqueKeysWithValues: players.map { ($0, startingPoints[$0] ?? 0) })]
        for round in rounds {
            checkpoints.append(checkpoints[checkpoints.count - 1].merging(round.points, uniquingKeysWith: +)
                .filter { checkpoints[0][$0.key] != nil })
        }

        // Only the last round can be open, so the complete ones keep their numbers
        let complete = rounds.indices.filter { rounds[$0].isComplete }
        let results = complete.map { Self.results(of: rounds[$0].points, for: players, lowScoreWins: lowScoreWins) }
        let leaders = complete.map { index in
            Self.leaders(in: checkpoints[index + 1], lowScoreWins: lowScoreWins)
        }
        let stats = players.map { player in
            let points = results.compactMap { $0[player]?.points }
            return (player, PlayerStats(results: results.compactMap { $0[player] },
                                        roundsLed: leaders.count { $0.contains(player) },
                                        best: lowScoreWins ? points.min() : points.max()))
        }
        let allPoints = stats.flatMap { $0.1.points }

        self.completeRounds = complete.count
        self.players = Dictionary(stats) { first, _ in first }
        self.averagePoints = allPoints.isEmpty ? nil : Double(allPoints.reduce(0, +)) / Double(allPoints.count)
        self.pointRange = allPoints.min().flatMap { lowest in allPoints.max().map { lowest...$0 } }
        self.bestRound = Self.bestRound(in: results, order: players, lowScoreWins: lowScoreWins)
        self.hotStreak = Self.hotStreak(in: results, order: players)
        self.mostConsistent = Self.mostConsistent(stats)
        (self.leadChanges, self.biggestLead) = Self.leads(through: checkpoints, lowScoreWins: lowScoreWins)
        self.leadMargin = Self.margin(of: checkpoints[checkpoints.count - 1], lowScoreWins: lowScoreWins)
        self.biggestClimb = Self.biggestClimb(through: checkpoints.dropFirst(),
                                              order: players,
                                              lowScoreWins: lowScoreWins)
    }

    /// Whether each player won the round, which, like the round table, takes points in high-score games
    private static func results(of points: [PlayerID: Int],
                                for players: [PlayerID],
                                lowScoreWins: Bool) -> [PlayerID: RoundResult] {
        let points = points.filter { players.contains($0.key) }
        let standings = Standings(scores: Array(points.values), lowScoreWins: lowScoreWins)
        return Dictionary(uniqueKeysWithValues: players.map { player in
            let value = points[player]
            return (player, RoundResult(points: value, won: value.map { standings.place(of: $0) == 0 } ?? false))
        })
    }

    /// Everyone in first place on `totals`, which in high-score games takes points
    private static func leaders(in totals: [PlayerID: Int], lowScoreWins: Bool) -> Set<PlayerID> {
        let standings = Standings(scores: Array(totals.values), lowScoreWins: lowScoreWins)
        return Set(totals.filter { standings.place(of: $0.value) == 0 }.keys)
    }

    /// The best points anyone scored, which always won its round. The earliest holds a tie.
    private static func bestRound(in results: [[PlayerID: RoundResult]],
                                  order: [PlayerID],
                                  lowScoreWins: Bool) -> Record? {
        var best: Record?
        for (index, round) in results.enumerated() {
            for player in order {
                guard let result = round[player], result.won, let points = result.points else {
                    continue
                }
                if best.map({ lowScoreWins ? points < $0.value : points > $0.value }) ?? true {
                    best = Record(player: player, value: points, round: index + 1)
                }
            }
        }
        return best
    }

    /// The longest run of round wins, at least two, held by whoever reached it first
    private static func hotStreak(in results: [[PlayerID: RoundResult]], order: [PlayerID]) -> Record? {
        var longest: Record?
        // Each player's current run and the round it started
        var streaks = [PlayerID: (length: Int, start: Int)]()
        for (index, round) in results.enumerated() {
            for player in order {
                guard round[player]?.won == true else {
                    streaks[player] = nil
                    continue
                }
                let streak = (length: (streaks[player]?.length ?? 0) + 1, start: streaks[player]?.start ?? index + 1)
                streaks[player] = streak
                if streak.length >= 2, streak.length > longest?.value ?? 0 {
                    longest = Record(player: player, value: streak.length, round: streak.start)
                }
            }
        }
        return longest
    }

    /// The sole leader on `totals` and how far ahead they are, if one places
    private static func soleLeader(in totals: [PlayerID: Int],
                                   lowScoreWins: Bool) -> (player: PlayerID, margin: Int)? {
        let standings = Standings(scores: Array(totals.values), lowScoreWins: lowScoreWins)
        guard let best = standings.winningScore, let leader = totals.first(where: { $0.value == best })?.key else {
            return nil
        }
        let others = totals.filter { $0.key != leader }.values
        guard let runnerUp = lowScoreWins ? others.min() : others.max() else {
            return nil
        }
        return (leader, abs(best - runnerUp))
    }

    /// Counts lead changes and finds the widest lead, which has to come after a round
    private static func leads(through checkpoints: [[PlayerID: Int]], lowScoreWins: Bool) -> (Int, Record?) {
        var changes = 0
        var leader: PlayerID?
        var biggest: Record?
        for (index, totals) in checkpoints.enumerated() {
            guard let current = soleLeader(in: totals, lowScoreWins: lowScoreWins) else {
                continue
            }
            if let leader, leader != current.player {
                changes += 1
            }
            leader = current.player
            if index > 0, current.margin > biggest?.value ?? 0 {
                biggest = Record(player: current.player, value: current.margin, round: index)
            }
        }
        return (changes, biggest)
    }

    /// The gap between first and second, which is zero when they're tied
    private static func margin(of totals: [PlayerID: Int], lowScoreWins: Bool) -> Int? {
        guard totals.count >= 2, totals.values.contains(where: { $0 != 0 }) else {
            return nil
        }
        let ranked = totals.values.sorted(by: lowScoreWins ? { $0 < $1 } : { $0 > $1 })
        return abs(ranked[0] - ranked[1])
    }

    /// The most places anyone has climbed from their lowest rank to where they stand now
    private static func biggestClimb(through checkpoints: ArraySlice<[PlayerID: Int]>,
                                     order: [PlayerID],
                                     lowScoreWins: Bool) -> Climb? {
        let ranks = checkpoints.map { totals in
            let standings = Standings(scores: Array(totals.values), lowScoreWins: lowScoreWins)
            return totals.compactMapValues(standings.rank(of:))
        }
        guard let current = ranks.last else {
            return nil
        }

        var biggest: Climb?
        for player in order {
            guard let now = current[player],
                  let lowest = ranks.compactMap({ $0[player] }).max(),
                  lowest > now else {
                continue
            }
            // A bigger climb wins, then the one ending higher up, then join order
            if let biggest, (biggest.fromRank - biggest.toRank, -biggest.toRank) >= (lowest - now, -now) {
                continue
            }
            biggest = Climb(player: player, fromRank: lowest, toRank: now)
        }
        return biggest
    }

    /// The steadiest player among those with enough rounds, when there's more than one to compare
    private static func mostConsistent(_ players: [(PlayerID, PlayerStats)]) -> Consistency? {
        let candidates = players.compactMap { player, stats -> Consistency? in
            let points = stats.points
            guard points.count >= consistencyMinimumRounds, let average = stats.average else {
                return nil
            }
            let variance = points.reduce(0) { $0 + (Double($1) - average) * (Double($1) - average) }
                / Double(points.count)
            return Consistency(player: player, deviation: variance.squareRoot())
        }
        guard candidates.count >= 2 else {
            return nil
        }
        // The first in join order wins ties
        return candidates.min { $0.deviation < $1.deviation }
    }
}

extension GameStats where PlayerID == PersistentIdentifier {
    /// The stats for `game`, keyed by each player's `persistentModelID`
    init(game: Game) {
        let players = game.players
        self.init(players: players.map(\.persistentModelID),
                  startingPoints: Dictionary(players.map { ($0.persistentModelID, $0.unrecordedPoints) }) { $0 + $1 },
                  rounds: game.rounds.map { round in
                      // Two devices can each add an entry for the same player, so they're added up like `points(for:)`
                      var points = [PersistentIdentifier: Int]()
                      for entry in round.storedEntries ?? [] {
                          if let player = entry.player {
                              points[player.persistentModelID, default: 0] += entry.points
                          }
                      }
                      return RoundPoints(points: points, isComplete: round.isComplete)
                  },
                  lowScoreWins: game.lowScoreWins)
    }
}
