//
// Standings
// ScoreTally
//
// Created on 2026-10-09
//

/// Places a set of scores using standard competition ranking, so tied scores share a place
struct Standings {
    let lowScoreWins: Bool
    /// Whether anyone has scored yet
    let hasStarted: Bool
    private let rankedScores: [Int]
    /// Where each score first appears in `rankedScores`, so tied scores share a place
    private let firstIndices: [Int: Int]

    init(scores: [Int], lowScoreWins: Bool) {
        self.lowScoreWins = lowScoreWins
        self.rankedScores = scores.sorted(by: lowScoreWins ? (<) : (>))
        self.hasStarted = scores.contains { $0 != 0 }
        var firstIndices = [Int: Int]()
        for (index, score) in rankedScores.enumerated() where firstIndices[score] == nil {
            firstIndices[score] = index
        }
        self.firstIndices = firstIndices
    }

    /// The zero-based place for `score`, or `nil` if it doesn't place.
    /// Nobody places before the game starts, and high-score games need points to place.
    func place(of score: Int) -> Int? {
        guard hasStarted, lowScoreWins || score > 0 else {
            return nil
        }
        return firstIndices[score]
    }

    /// The zero-based rank for `score` among every score given, or `nil` before the game starts.
    /// Unlike `place(of:)`, this doesn't need points, so the full order shows.
    func rank(of score: Int) -> Int? {
        guard hasStarted else {
            return nil
        }
        return firstIndices[score]
    }

    /// The best score, if it places and nobody else shares it
    var winningScore: Int? {
        guard let best = rankedScores.first,
              place(of: best) == 0,
              rankedScores.dropFirst().first != best else {
            return nil
        }
        return best
    }
}

/// A game's players ranked in the full order, built once so a view can look up every player
/// without re-sorting or re-adding their points for each one.
/// High-score games leave out players who have never scored; low-score games rank everyone.
struct Ranking {
    let standings: Standings
    /// The total of each ranked player
    private let totals: [ObjectIdentifier: Int]
    private let best: Int?
    private let worst: Int?

    init(players: [Player], lowScoreWins: Bool) {
        let ranked = lowScoreWins ? players : players.filter(\.hasScored)
        let scores = ranked.map(\.total)
        standings = Standings(scores: scores, lowScoreWins: lowScoreWins)
        totals = Dictionary(zip(ranked.map(ObjectIdentifier.init), scores)) { first, _ in first }
        let (low, high) = (scores.min(), scores.max())
        (best, worst) = lowScoreWins ? (low, high) : (high, low)
    }

    /// The player's zero-based rank, with ties sharing a rank, or `nil` if they don't rank
    func rank(of player: Player) -> Int? {
        totals[ObjectIdentifier(player)].flatMap(standings.rank(of:))
    }

    /// `players` with their ranks, ranked ones first by place and then anyone without one, each in the order given
    func ordered(_ players: [Player]) -> [(player: Player, rank: Int?)] {
        players.enumerated()
            .map { (player: $0.element, rank: rank(of: $0.element), order: $0.offset) }
            .sorted { ($0.rank ?? .max, $0.order) < ($1.rank ?? .max, $1.order) }
            .map { (player: $0.player, rank: $0.rank) }
    }

    /// How close the player is to the lead, from 0 for last to 1 for leading, or `nil` if they don't rank
    func lead(of player: Player) -> Double? {
        guard let total = totals[ObjectIdentifier(player)], standings.rank(of: total) != nil else {
            return nil
        }
        guard let best, let worst, best != worst else {
            return 1
        }
        return Double(total - worst) / Double(best - worst)
    }
}
