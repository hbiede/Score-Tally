//
// DeletionTests
// ScoreTallyTests
//
// Created on 2026-10-09
//

import Foundation
import SwiftData
import Testing
@testable import ScoreTally

@MainActor
struct DeletionTests {
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

    @Test func deletingAPlayerRemovesTheirEntries() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        game.completeRound(with: zip(players, [3, 4]))
        players[0].delete()
        try context.save()

        #expect(game.rounds[0].storedEntries?.count == 1)
        #expect(try context.fetchCount(FetchDescriptor<ScoreEntry>()) == 1)
    }

    @Test func deletingARoundRemovesItsEntries() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        game.completeRound(with: zip(players, [3, 4]))
        game.completeRound(with: zip(players, [1, 2]))
        context.delete(game.rounds[0])
        try context.save()

        #expect(game.rounds.count == 1)
        #expect(try context.fetchCount(FetchDescriptor<ScoreEntry>()) == 2)
        // Totals follow the entries, so the round's points go with it
        #expect(players.map(\.total) == [1, 2])
        #expect(players.map(\.unrecordedPoints) == [0, 0])
    }

    @Test func deletingAPlayerRemovesRoundsOnlyTheyScoredIn() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        game.completeRound(with: zip(players, [3, 4]))
        players[0].increment(by: 2)
        players[0].delete()
        try context.save()

        #expect(game.rounds.count == 1)
        #expect(game.openRound == nil)
        #expect(try context.fetchCount(FetchDescriptor<Round>()) == 1)
    }

    @Test func deletingAGameLoadedFromDisk() throws {
        let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            let container = try ModelContainer(for: Game.self, configurations: ModelConfiguration(url: url))
            let game = Game(name: "Test")
            container.mainContext.insert(game)
            let players = ["Alex", "Mom"].map { game.addPlayer(with: $0) }
            game.completeRound(with: zip(players, [3, 4]))
            players[0].increment()
            try container.mainContext.save()
        }

        // A new container only has what it loads from disk, like the app after relaunching
        let container = try ModelContainer(for: Game.self, configurations: ModelConfiguration(url: url))
        let context = container.mainContext
        let game = try #require(try context.fetch(FetchDescriptor<Game>()).first)
        game.delete()
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<ScoreEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Round>()) == 0)
    }

    @Test func deletingAGameRemovesItsRoundsAndEntries() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        game.completeRound(with: zip(players, [3, 4]))
        players[0].increment()
        context.delete(game)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Round>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ScoreEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Player>()) == 0)
    }
}
