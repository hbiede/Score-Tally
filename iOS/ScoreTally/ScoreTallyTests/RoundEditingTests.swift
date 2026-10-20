//
// RoundEditingTests
// ScoreTallyTests
//
// Created on 2026-10-16
//

import Foundation
import SwiftData
import Testing
@testable import ScoreTally

@MainActor
struct RoundEditingTests {
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

    @Test func editingARoundChangesTheTotals() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])
        game.completeRound(with: zip(players, [3, 4]))
        game.completeRound(with: zip(players, [5, 1]))

        let first = game.rounds[0]
        game.setPoints([(players[0], 10)], in: first)
        try context.save()

        #expect(first.points(for: players[0]) == 10)
        #expect(first.points(for: players[1]) == 4)
        #expect(players.map(\.total) == [15, 5])
        #expect(players.map(\.score) == [15, 5])
        #expect(game.runningTotals(for: players[0]) == [10, 15])
    }

    @Test func clearingAPlayerTakesThemOutOfTheRound() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])
        game.completeRound(with: zip(players, [3, 4]))

        let round = game.rounds[0]
        game.setPoints([(players[1], nil)], in: round)
        try context.save()

        #expect(round.points(for: players[1]) == nil)
        #expect(players[1].total == 0)
        #expect(game.rounds.count == 1)
        #expect(try context.fetchCount(FetchDescriptor<ScoreEntry>()) == 1)
    }

    @Test func clearingEveryoneDeletesTheRound() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])
        game.completeRound(with: zip(players, [3, 4]))
        game.completeRound(with: zip(players, [5, 1]))

        game.setPoints(players.map { ($0, nil) }, in: game.rounds[0])
        try context.save()

        #expect(game.rounds.count == 1)
        #expect(players.map(\.total) == [5, 1])
        #expect(try context.fetchCount(FetchDescriptor<Round>()) == 1)
    }

    @Test func deletingARoundTakesItsPointsOffTheTotals() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])
        game.completeRound(with: zip(players, [3, 4]))
        game.completeRound(with: zip(players, [5, 1]))

        game.deleteRound(game.rounds[0])
        try context.save()

        #expect(game.rounds.count == 1)
        #expect(players.map(\.total) == [5, 1])
        #expect(players.map(\.score) == [5, 1])
        #expect(try context.fetchCount(FetchDescriptor<Round>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<ScoreEntry>()) == 2)
    }

    @Test func deletingTheOpenRoundLetsANewOneStart() throws {
        let (game, players) = makeGame(players: ["Alex"])
        game.completeRound(with: zip(players, [2]))
        players[0].increment(by: 3)

        game.deleteRound(try #require(game.openRound))
        players[0].increment()

        #expect(game.rounds.count == 2)
        #expect(players[0].total == 3)
    }

    @Test func editingKeepsPointsFromBeforeRounds() throws {
        let game = Game(name: "Test")
        context.insert(game)
        let alex = game.addPlayer(with: "Alex", score: 7)
        game.completeRound(with: [(alex, 3)])

        game.setPoints([(alex, 5)], in: game.rounds[0])

        #expect(alex.unrecordedPoints == 7)
        #expect(alex.total == 12)
    }

    @Test func editingMergesEntriesFromAnotherDevice() throws {
        let (game, players) = makeGame(players: ["Alex"])
        let alex = players[0]
        alex.increment()
        // Another device added its own entry to the same round before syncing
        let round = try #require(game.openRound)
        let synced = ScoreEntry(points: 2)
        context.insert(synced)
        alex.storedEntries?.append(synced)
        round.storedEntries?.append(synced)

        game.setPoints([(alex, 4)], in: round)
        try context.save()

        #expect(round.points(for: alex) == 4)
        #expect(alex.total == 4)
        #expect(round.storedEntries?.count == 1)
        #expect(try context.fetchCount(FetchDescriptor<ScoreEntry>()) == 1)
    }

    @Test func settingTheSamePointsChangesNothing() {
        let (game, players) = makeGame(players: ["Alex"])
        game.completeRound(with: zip(players, [3]))
        // As if from an older version, which never set it
        players[0].recordedPoints = nil

        game.setPoints([(players[0], 3)], in: game.rounds[0])

        #expect(players[0].recordedPoints == nil)
        #expect(players[0].total == 3)
    }

    @Test func playersCanBeAddedInAChosenColor() {
        let (game, _) = makeGame(players: [])

        let alex = game.addPlayer(with: "Alex", color: .green)
        let mom = game.addPlayer(with: "Mom")

        #expect(alex.color == .green)
        #expect(mom.color == .blue)
    }

    @Test func firstUnusedColorSkipsTakenOnes() {
        #expect(PlayerColor.firstUnused(by: []) == .blue)
        #expect(PlayerColor.firstUnused(by: [.blue, .orange]) == .purple)
        #expect(PlayerColor.firstUnused(by: PlayerColor.palette) == .blue)
    }
}
