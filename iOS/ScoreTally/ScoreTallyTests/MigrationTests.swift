//
// MigrationTests
// ScoreTallyTests
//
// Created on 2026-10-16
//

import Foundation
import SwiftData
import Testing
@testable import ScoreTally

@MainActor
struct MigrationTests {
    @Test func migratingFromVersion1KeepsGamesAndScores() throws {
        let url = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            let schema = Schema(versionedSchema: ScoreTallySchemaV1.self)
            let container = try ModelContainer(for: schema,
                                               configurations: ModelConfiguration(schema: schema, url: url))
            let game = ScoreTallySchemaV1.Game(name: "Test", lowScoreWins: true)
            container.mainContext.insert(game)
            for (name, score) in [("Alex", 7), ("Mom", 3)] {
                let player = ScoreTallySchemaV1.Player(name: name, score: score)
                container.mainContext.insert(player)
                game.storedPlayerList?.append(player)
            }
            try container.mainContext.save()
        }

        let schema = Schema(versionedSchema: ScoreTallySchemaV2.self)
        let container = try ModelContainer(for: schema,
                                           migrationPlan: ScoreTallyMigrationPlan.self,
                                           configurations: ModelConfiguration(schema: schema, url: url))
        let game = try #require(try container.mainContext.fetch(FetchDescriptor<Game>()).first)

        #expect(game.name == "Test")
        #expect(game.lowScoreWins)
        #expect(game.rounds.isEmpty)
        #expect(game.players.map(\.total).sorted() == [3, 7])
        #expect(game.players.allSatisfy { $0.recordedPoints == nil && $0.storedColor == nil })
        #expect(game.winner?.name == "Mom")

        // New rounds record on top of the migrated scores
        game.players.first { $0.name == "Mom" }?.increment(by: 2)
        try container.mainContext.save()
        #expect(game.players.map(\.total).sorted() == [5, 7])
        #expect(game.rounds.count == 1)
    }
}
