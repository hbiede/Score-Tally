//
// StandingsTests
// ScoreTallyTests
//
// Created on 2026-10-09
//

import Testing
@testable import ScoreTally

struct StandingsTests {
    @Test func nobodyPlacesBeforeTheGameStarts() {
        for lowScoreWins in [false, true] {
            let standings = Standings(scores: [0, 0, 0], lowScoreWins: lowScoreWins)

            #expect(!standings.hasStarted)
            #expect(standings.place(of: 0) == nil)
            #expect(standings.winningScore == nil)
        }
    }

    @Test func highScoreGamesRankHighestFirst() {
        let standings = Standings(scores: [3, 10, 6], lowScoreWins: false)

        #expect(standings.place(of: 10) == 0)
        #expect(standings.place(of: 6) == 1)
        #expect(standings.place(of: 3) == 2)
        #expect(standings.winningScore == 10)
    }

    @Test func lowScoreGamesRankLowestFirst() {
        let standings = Standings(scores: [3, 10, 6], lowScoreWins: true)

        #expect(standings.place(of: 3) == 0)
        #expect(standings.place(of: 6) == 1)
        #expect(standings.place(of: 10) == 2)
        #expect(standings.winningScore == 3)
    }

    @Test func tiesShareAPlaceAndSkipTheNext() {
        let standings = Standings(scores: [10, 10, 5, 2], lowScoreWins: false)

        #expect(standings.place(of: 10) == 0)
        #expect(standings.place(of: 5) == 2)
        #expect(standings.place(of: 2) == 3)
    }

    @Test func aTieForFirstHasNoWinner() {
        #expect(Standings(scores: [10, 10, 5], lowScoreWins: false).winningScore == nil)
        #expect(Standings(scores: [2, 2, 5], lowScoreWins: true).winningScore == nil)
    }

    @Test func rankIncludesEveryScore() {
        let standings = Standings(scores: [5, 0, -2], lowScoreWins: false)

        #expect(standings.rank(of: 5) == 0)
        #expect(standings.rank(of: 0) == 1)
        #expect(standings.rank(of: -2) == 2)
    }

    @Test func rankSharesTies() {
        let standings = Standings(scores: [4, 9, 4, 1], lowScoreWins: true)

        #expect(standings.rank(of: 1) == 0)
        #expect(standings.rank(of: 4) == 1)
        #expect(standings.rank(of: 9) == 3)
    }

    @Test func nobodyRanksBeforeTheGameStarts() {
        #expect(Standings(scores: [0, 0], lowScoreWins: false).rank(of: 0) == nil)
    }

    @Test func highScoreGamesNeedPointsToPlace() {
        let standings = Standings(scores: [5, 0, -2], lowScoreWins: false)

        #expect(standings.place(of: 5) == 0)
        #expect(standings.place(of: 0) == nil)
        #expect(standings.place(of: -2) == nil)
    }

    @Test func highScoreGamesNeedAPositiveLeaderToHaveAWinner() {
        #expect(Standings(scores: [0, -3], lowScoreWins: false).winningScore == nil)
    }

    @Test func lowScoreGamesCountNegativeScores() {
        let standings = Standings(scores: [-2, -1, 0], lowScoreWins: true)

        #expect(standings.hasStarted)
        #expect(standings.place(of: -2) == 0)
        #expect(standings.place(of: 0) == 2)
        #expect(standings.winningScore == -2)
    }

    @Test func singlePlayerWinsOnceTheyScore() {
        #expect(Standings(scores: [4], lowScoreWins: false).winningScore == 4)
        #expect(Standings(scores: [0], lowScoreWins: false).winningScore == nil)
    }

    @Test func noPlayersHasNoWinner() {
        let standings = Standings(scores: [], lowScoreWins: false)

        #expect(!standings.hasStarted)
        #expect(standings.winningScore == nil)
    }

    @Test(arguments: [(0, "🥇"), (1, "🥈"), (2, "🥉"), (3, ""), (nil, "")] as [(Int?, String)])
    func rankingEmoji(rank: Int?, emoji: String) {
        #expect(rank.rankingEmoji() == emoji)
    }

    @Test func rankingEmojiShowsLossOfPlace() {
        #expect((nil as Int?).rankingEmoji(showLossOfPlace: true) == "❌")
        #expect((3 as Int?).rankingEmoji(showLossOfPlace: true) == "❌")
        #expect((0 as Int?).rankingEmoji(showLossOfPlace: true) == "🥇")
    }
}
