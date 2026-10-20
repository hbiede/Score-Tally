//
// ScoreTallySchema
// ScoreTally
//
// Created on 2026-10-16
//

import Foundation
import SwiftData

/// The models as version 1.3 shipped them, before rounds were recorded.
/// SwiftData matches an existing store to a version by these exact properties, so never change them.
enum ScoreTallySchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [Game.self, Player.self]
    }

    @Model
    final class Game {
        #Index<Game>([\.name, \.createdDate])

        var name = ""
        var createdDate = Date.now
        var selected = false
        var lowScoreWins = false

        @Relationship(deleteRule: .cascade)
        var storedPlayerList: [Player]? = [Player]()

        init(name: String, lowScoreWins: Bool = false, createdDate: Date = .now) {
            self.name = name
            self.lowScoreWins = lowScoreWins
            self.createdDate = createdDate
        }
    }

    @Model
    final class Player {
        #Index<Player>([\.name, \.creationDate])

        var name = ""
        var score = 0
        var creationDate = Date.now

        @Relationship(inverse: \Game.storedPlayerList)
        var game: Game?

        init(name: String, score: Int = 0) {
            self.name = name
            self.score = score
            self.creationDate = .now
        }
    }
}

/// Adds rounds, score entries, `Player.recordedPoints` and `Player.storedColor`, and drops `Game.selected`.
/// These are the app's current models; freeze copies in here before changing them for a version 3.
enum ScoreTallySchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [Game.self, Player.self, Round.self, ScoreEntry.self]
    }
}

/// Every change so far only adds optional or defaulted properties or removes one, so SwiftData can
/// migrate the store itself. CloudKit only supports lightweight stages, so keep it that way.
enum ScoreTallyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ScoreTallySchemaV1.self, ScoreTallySchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: ScoreTallySchemaV1.self, toVersion: ScoreTallySchemaV2.self)]
    }
}

extension ModelContainer {
    /// The app's container, migrating an older store to the current schema
    static func scoreTally() throws -> ModelContainer {
        let schema = Schema(versionedSchema: ScoreTallySchemaV2.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema,
                                  migrationPlan: ScoreTallyMigrationPlan.self,
                                  configurations: [configuration])
    }
}
