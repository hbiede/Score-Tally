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
    #Unique([\Game.name])
    #Index([\Game.name, \.createdDate])

    var name: String
    var createdDate: Date
    var selected = false

    @Relationship(deleteRule: .cascade)
    var storedPlayerList: [Player] = [Player]()
    var players: [Player] {
        self.storedPlayerList.sorted(by: { $0.creationDate < $1.creationDate })
    }

    var lowScoreWins: Bool

    var sortedPlayers: [Player] {
        storedPlayerList.sorted(by: lowScoreWins ? { $0 < $1 } : { $0 > $1 })
    }

    init(name: String, lowScoreWins: Bool = false, createdDate: Date = .now) {
        self.name = name
        self.lowScoreWins = lowScoreWins
        self.createdDate = createdDate
    }

    func addPlayer(with name: String, score: Int = 0) {
        let player = Player(name: name, score: score)
        modelContext?.insert(player)
        storedPlayerList.append(player)
    }

    func ranking(for player: Player) -> Int {
        Game.ranking(for: player, in: players, with: lowScoreWins)
    }

    public static func ranking(for player: Player, in playerList: [Player], with lowScoreWins: Bool = false) -> Int {
        if playerList.allSatisfy({ $0.score == 0 }) {
            return -1
        }

        return playerList
            .sorted(by: lowScoreWins ? { $0 < $1 } : { $0 > $1 })
            .map(\.score)
            .firstIndex(of: player.score) ?? -1
    }
}

extension Game: Equatable {
    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.name == rhs.name &&
        lhs.createdDate == rhs.createdDate &&
        lhs.players.count == rhs.players.count &&
        lhs.players.enumerated().allSatisfy { (index, player) in
            player == rhs.players[index]
        }
    }
}

extension Game: CustomStringConvertible {
    var description: String {
        "\(name): \(players.map(\.description).formatted(.list(type: .and)))"
    }
}
