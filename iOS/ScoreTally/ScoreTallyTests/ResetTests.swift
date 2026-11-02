//
// ResetTests
// ScoreTallyTests
//
// Created on 2026-10-21
//

import Foundation
import SwiftData
import Testing
@testable import ScoreTally

@MainActor
struct ResetTests {
    // The context doesn't keep its container alive
    let container: ModelContainer
    var context: ModelContext {
        container.mainContext
    }

    init() throws {
        container = try ModelContainer(for: Game.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func makeGame(players names: [String]) -> (Game, [Player]) {
        let game = Game(name: "Test")
        context.insert(game)
        return (game, names.map { game.addPlayer(with: $0) })
    }

    @Test func resettingAPlayerIsRecorded() {
        let (game, players) = makeGame(players: ["Alex"])

        game.completeRound(with: zip(players, [7]))
        players[0].resetScore()

        #expect(players[0].score == 0)
        #expect(game.rounds.count == 2)
        #expect(game.rounds[1].points(for: players[0]) == -7)
        #expect(players[0].unrecordedPoints == 0)
    }

    @Test func resettingTheGameClearsRounds() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        game.completeRound(with: zip(players, [3, 4]))
        players[0].increment()
        game.reset()
        try context.save()

        #expect(game.rounds.isEmpty)
        #expect(players.map(\.score) == [0, 0])
        #expect(players.allSatisfy { $0.unrecordedPoints == 0 })
        #expect(try context.fetchCount(FetchDescriptor<ScoreEntry>()) == 0)
    }

    @Test func resettingAZeroScoreDoesNotStartARound() {
        let (game, players) = makeGame(players: ["Alex"])

        players[0].resetScore()

        #expect(game.rounds.isEmpty)
    }

    @Test func freshGameHasNothingToReset() {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        #expect(!game.canReset)
        let anyResettable = players.contains(where: \.canResetScore)
        #expect(!anyResettable)
    }

    @Test func scoringAllowsResetting() {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        players[0].increment()

        #expect(game.canReset)
        #expect(players[0].canResetScore)
        #expect(!players[1].canResetScore)
    }

    @Test func resettingAScoreDisablesResettingIt() {
        let (_, players) = makeGame(players: ["Alex"])

        players[0].increment(by: 3)
        players[0].resetScore()

        #expect(!players[0].canResetScore)
    }

    @Test func roundHistoryAllowsResettingTheGame() {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        game.completeRound(with: zip(players, [0, 0]))

        #expect(game.canReset)
        let anyResettable = players.contains(where: \.canResetScore)
        #expect(!anyResettable)
    }

    @Test func resettingTheGameDisablesResettingIt() {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        game.completeRound(with: zip(players, [3, 4]))
        game.reset()

        #expect(!game.canReset)
    }

    @Test func resettingTheGameStartsRoundsOver() {
        let (game, players) = makeGame(players: ["Alex"])

        game.completeRound(with: zip(players, [3]))
        game.reset()
        players[0].increment()

        #expect(game.rounds.count == 1)
        #expect(game.openRound?.points(for: players[0]) == 1)
        #expect(players[0].unrecordedPoints == 0)
    }
}
