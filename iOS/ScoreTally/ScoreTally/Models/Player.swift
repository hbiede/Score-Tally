//
// Player
// ScoreTally 
//
// Created on 7/5/24
//

import Foundation
import SwiftData

@Model
final class Player {
    #Unique([\Player.name, \.game])
    #Index([\Player.name, \.creationDate])

    var name: String
    var score: Int
    var creationDate: Date

    @Relationship(inverse: \Game.storedPlayerList)
    var game: Game?

    init(name: String, score: Int = 0) {
        self.name = name
        self.score = score
        self.creationDate = .now
    }

    func increment(by value: Int = 1) {
        score += value
    }
}

extension Player: Equatable {
    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.name == rhs.name && lhs.score == rhs.score
    }
}

extension Player: AdditiveArithmetic {
    static var zero: Player {
        Player(name: NSLocalizedString("default-player-name", comment: "Name for a default-created player"))
    }

    static func + (lhs: Player, rhs: Player) -> Player {
        Player(name: lhs.name, score: lhs.score + rhs.score)
    }

    static func + (lhs: Player, rhs: Int) -> Player {
        Player(name: lhs.name, score: lhs.score + rhs)
    }

    static func - (lhs: Player, rhs: Player) -> Player {
        Player(name: lhs.name, score: lhs.score - rhs.score)
    }

    static func += (lhs: inout Player, rhs: Player) {
        lhs.score += rhs.score
    }

    static func += (lhs: inout Player, rhs: Int) {
        lhs.score += rhs
    }

    static func -= (lhs: inout Player, rhs: Player) {
        lhs.score -= rhs.score
    }

    static func -= (lhs: inout Player, rhs: Int) {
        lhs.score -= rhs
    }
}

extension Player: Comparable {
    @inlinable static func < (lhs: Player, rhs: Player) -> Bool {
        lhs.score < rhs.score
    }
    @inlinable static func <= (lhs: Player, rhs: Player) -> Bool {
        lhs.score <= rhs.score
    }
    @inlinable static func > (lhs: Player, rhs: Player) -> Bool {
        lhs.score > rhs.score
    }
    @inlinable static func >= (lhs: Player, rhs: Player) -> Bool {
        lhs.score >= rhs.score
    }
}

extension Player: CustomStringConvertible {
    var description: String {
        "\(name): \(score)"
    }
}
