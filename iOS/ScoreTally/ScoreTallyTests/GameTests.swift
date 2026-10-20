//
// GameTests
// ScoreTallyTests
//
// Created on 2026-10-09
//

import Foundation
import SwiftData
import Testing
@testable import ScoreTally

@MainActor
struct GameTests {
    // The context doesn't keep its container alive
    let container: ModelContainer
    var context: ModelContext {
        container.mainContext
    }

    init() throws {
        container = try ModelContainer(for: Game.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func makeGame(scores: [(String, Int)], lowScoreWins: Bool = false) -> Game {
        let game = Game(name: "Test", lowScoreWins: lowScoreWins)
        context.insert(game)
        for (name, score) in scores {
            game.addPlayer(with: name, score: score)
        }
        return game
    }

    @Test func winnerIsTheSoleLeader() {
        let game = makeGame(scores: [("Alex", 10), ("Mom", 12), ("Dad", 6)])

        #expect(game.winner?.name == "Mom")
    }

    @Test func tiedPlayersWithTheSameNameHaveNoWinner() {
        let game = makeGame(scores: [("Sam", 10), ("Sam", 10), ("Dad", 6)])

        #expect(game.winner == nil)
    }

    @Test func lowScoreWinnerWithNegativeScores() {
        let game = makeGame(scores: [("Alex", -2), ("Mom", -1)], lowScoreWins: true)

        #expect(game.winner?.name == "Alex")
    }

    @Test func placeMatchesStandings() throws {
        let game = makeGame(scores: [("Alex", 10), ("Mom", 12), ("Dad", 10), ("Derek", 0)])
        let players = Dictionary(uniqueKeysWithValues: game.players.map { ($0.name, $0) })

        #expect(game.standings.place(of: try #require(players["Mom"]).total) == 0)
        #expect(game.standings.place(of: try #require(players["Alex"]).total) == 1)
        #expect(game.standings.place(of: try #require(players["Dad"]).total) == 1)
        #expect(game.standings.place(of: try #require(players["Derek"]).total) == nil)
    }

    @Test func playersWithTheSameNameAndScoreAreDistinct() {
        let game = makeGame(scores: [("Sam", 3), ("Sam", 3)])

        #expect(game.players[0] != game.players[1])
        #expect(Set(game.players).count == 2)
    }

    @Test func highScoreGamesDoNotRankPlayersWhoNeverScored() {
        let game = makeGame(scores: [("Alex", 0), ("Mom", 0), ("Dad", 0)])
        let players = game.players

        players[0].increment(by: 5)
        players[2].increment(by: -2)

        #expect(game.ranking.rank(of: players[0]) == 0)
        #expect(game.ranking.rank(of: players[1]) == nil)
        // Ranks right after the scorers rather than behind the player who never scored
        #expect(game.ranking.rank(of: players[2]) == 1)
    }

    @Test func playersBackAtZeroStillRank() {
        let game = makeGame(scores: [("Alex", 0), ("Mom", 0)])
        let players = game.players

        game.completeRound(with: zip(players, [5, 3]))
        players[1].resetScore()

        #expect(players[1].hasScored)
        #expect(game.ranking.rank(of: players[1]) == 1)
    }

    @Test func aRecordedZeroIsNotAScore() {
        let game = makeGame(scores: [("Alex", 0), ("Mom", 0)])
        let players = game.players

        game.completeRound(with: zip(players, [5, 0]))

        #expect(!players[1].hasScored)
        #expect(game.ranking.rank(of: players[1]) == nil)
    }

    @Test func lowScoreGamesRankEveryone() {
        let game = makeGame(scores: [("Alex", 0), ("Mom", 0)], lowScoreWins: true)
        let (alex, mom) = (game.players[0], game.players[1])

        alex.increment(by: 5)

        #expect(game.ranking.rank(of: mom) == 0)
        #expect(game.ranking.rank(of: alex) == 1)
    }

    @Test func playersWithEarlierPointsRank() {
        let game = makeGame(scores: [("Alex", 4), ("Mom", 9)])
        let (alex, mom) = (game.players[0], game.players[1])

        #expect(game.ranking.rank(of: mom) == 0)
        #expect(game.ranking.rank(of: alex) == 1)
    }

    @Test func colorsFollowJoinOrder() {
        let game = makeGame(scores: [("Alex", 0), ("Mom", 0), ("Dad", 0)])

        #expect(game.players.map(\.color) == Array(PlayerColor.palette.prefix(3)))
    }

    @Test func colorsStayPutWhenAPlayerLeaves() throws {
        let game = makeGame(scores: [("Alex", 0), ("Mom", 0), ("Dad", 0)])

        game.players[0].delete()
        try context.save()

        #expect(game.players.map(\.color) == [.orange, .purple])
    }

    @Test func colorsFromOlderVersionsStayPutWhenAPlayerLeaves() throws {
        let game = makeGame(scores: [("Alex", 0), ("Mom", 0), ("Dad", 0)])
        game.players.forEach { $0.storedColor = nil }

        game.players[0].delete()
        try context.save()

        #expect(game.players.map(\.color) == [.orange, .purple])
    }

    @Test func newPlayersTakeAFreeColor() {
        let game = makeGame(scores: [("Alex", 0), ("Mom", 0)])

        game.players[0].delete()
        let dad = game.addPlayer(with: "Dad")

        #expect(dad.color == .blue)
    }

    @Test func duplicatingCopiesTheRoundHistory() throws {
        let game = makeGame(scores: [("Alex", 2), ("Mom", 0)])
        let players = game.players
        game.completeRound(with: zip(players, [3, 0]))
        players[1].increment(by: 4)

        let copy = try #require(game.duplicate(named: "Copy"))

        #expect(copy.players.map(\.name) == ["Alex", "Mom"])
        #expect(copy.players.map(\.total) == [5, 4])
        #expect(copy.players.map(\.unrecordedPoints) == [2, 0])
        #expect(copy.players.map(\.color) == players.map(\.color))
        #expect(copy.rounds.map(\.isComplete) == [true, false])
        #expect(copy.rounds[0].points(for: copy.players[1]) == 0)
        #expect(copy.rounds[1].points(for: copy.players[1]) == 4)
        #expect(game.rounds.count == 2)
    }

    @Test func colorsCycleThroughThePalette() {
        let count = PlayerColor.palette.count

        #expect(PlayerColor.forJoinOrder(count) == PlayerColor.forJoinOrder(0))
        #expect(PlayerColor.forJoinOrder(count + 1) == PlayerColor.forJoinOrder(1))
    }

    @Test func customColorsAreStoredWithoutTakingAPaletteColor() throws {
        let game = makeGame(scores: [])
        let color = try #require(PlayerColor(rawValue: "#3478F6"))

        let alex = game.addPlayer(with: "Alex", color: color)

        #expect(alex.storedColor == "#3478F6")
        #expect(alex.color == color)
        #expect(game.nextColor == .blue)
        #expect(PlayerColor(rawValue: "#3478F") == nil)
    }

    @Test(arguments: [("Adam", "A"), ("Adam Brown", "AB"), ("mom", "M")])
    func initials(name: String, expected: String) {
        #expect(Player(name: name).initials == expected)
    }

    @Test func runningTotalsCarryForwardAndStartFromEarlierPoints() {
        let game = makeGame(scores: [("Alex", 2), ("Mom", 0)])
        let (alex, mom) = (game.players[0], game.players[1])

        game.completeRound(with: [(alex, 3), (mom, 5)])
        game.completeRound(with: [(mom, -1)])
        alex.increment(by: 4)

        #expect(game.runningTotals(for: alex) == [5, 5, 9])
        #expect(game.runningTotals(for: mom) == [5, 4, 4])
    }

    @Test func leadSpansLastToFirst() throws {
        let game = makeGame(scores: [("Alex", 12), ("Mom", 6), ("Dad", 0)])
        let (alex, mom, dad) = (game.players[0], game.players[1], game.players[2])

        #expect(game.ranking.lead(of: alex) == 1)
        #expect(game.ranking.lead(of: mom) == 0)
        // Never scored, so no place and no bar
        #expect(game.ranking.lead(of: dad) == nil)
    }

    @Test func leadFavorsLowScoresInLowScoreGames() {
        let game = makeGame(scores: [("Alex", 70), ("Mom", 80), ("Dad", 75)], lowScoreWins: true)

        #expect(game.ranking.lead(of: game.players[0]) == 1)
        #expect(game.ranking.lead(of: game.players[1]) == 0)
        #expect(game.ranking.lead(of: game.players[2]) == 0.5)
    }

    @Test func tiedPlayersAllLead() {
        let game = makeGame(scores: [("Alex", 5), ("Mom", 5)])

        #expect(game.players.allSatisfy { game.ranking.lead(of: $0) == 1 })
    }
}
