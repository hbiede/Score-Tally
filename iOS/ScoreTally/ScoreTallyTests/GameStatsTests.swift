//
// GameStatsTests
// ScoreTallyTests
//
// Created on 2026-10-16
//

import Foundation
import SwiftData
import Testing
@testable import ScoreTally

/// Names stand in for player IDs
private typealias Stats = GameStats<String>

struct GameStatsTests {
    private func complete(_ points: KeyValuePairs<String, Int>) -> Stats.RoundPoints {
        Stats.RoundPoints(points: Dictionary(uniqueKeysWithValues: Array(points)), isComplete: true)
    }

    private func open(_ points: KeyValuePairs<String, Int>) -> Stats.RoundPoints {
        Stats.RoundPoints(points: Dictionary(uniqueKeysWithValues: Array(points)), isComplete: false)
    }

    private func stats(_ players: [String],
                       startingPoints: [String: Int] = [:],
                       rounds: [Stats.RoundPoints],
                       lowScoreWins: Bool = false) -> Stats {
        Stats(players: players, startingPoints: startingPoints, rounds: rounds, lowScoreWins: lowScoreWins)
    }

    /// The lead passes from Mom to Alex, and Dad sits out the last round
    private var highScoreGame: Stats {
        stats(["Alex", "Mom", "Dad"], rounds: [
            complete(["Alex": 3, "Mom": 5, "Dad": 2]),
            complete(["Alex": 4, "Mom": 7, "Dad": 4]),
            complete(["Alex": 9, "Mom": 1, "Dad": 2]),
            complete(["Alex": 6, "Mom": 0])
        ])
    }

    @Test func aGameWithoutRoundsHasNoRecords() {
        let stats = stats(["Alex", "Mom"], rounds: [])

        #expect(stats.completeRounds == 0)
        #expect(stats.leadChanges == 0)
        #expect(stats.leadMargin == nil)
        #expect(stats.averagePoints == nil)
        #expect(stats.bestRound == nil)
        #expect(stats.hotStreak == nil)
        #expect(stats.biggestLead == nil)
        #expect(stats.biggestClimb == nil)
        #expect(stats.mostConsistent == nil)
        #expect(stats.players.mapValues(\.roundsPlayed) == ["Alex": 0, "Mom": 0])
        #expect(stats.players.values.allSatisfy { $0.average == nil && $0.best == nil && $0.roundsLed == 0 })
    }

    @Test func gameFigures() {
        let stats = highScoreGame

        #expect(stats.completeRounds == 4)
        #expect(stats.leadChanges == 1)
        #expect(stats.leadMargin == 9)
        #expect(stats.averagePoints == 43.0 / 11)
        #expect(stats.pointRange == 0...9)
    }

    @Test func records() {
        let stats = highScoreGame

        #expect(stats.bestRound == Stats.Record(player: "Alex", value: 9, round: 3))
        // Both leaders won two in a row, and Mom got there first
        #expect(stats.hotStreak == Stats.Record(player: "Mom", value: 2, round: 1))
        #expect(stats.biggestLead == Stats.Record(player: "Alex", value: 9, round: 4))
        #expect(stats.biggestClimb == Stats.Climb(player: "Alex", fromRank: 1, toRank: 0))
        // Dad's 2, 4, 2 is the steadiest
        #expect(stats.mostConsistent?.player == "Dad")
        #expect(abs((stats.mostConsistent?.deviation ?? 0) - (8.0 / 9).squareRoot()) < 0.0001)
    }

    @Test func playerFigures() throws {
        let players = highScoreGame.players
        let alex = try #require(players["Alex"])
        let mom = try #require(players["Mom"])
        let dad = try #require(players["Dad"])

        #expect(alex.roundsPlayed == 4)
        #expect(alex.average == 5.5)
        #expect(alex.best == 9)
        #expect(alex.roundsWon == 2)
        #expect(alex.roundsLed == 2)

        #expect(mom.roundsWon == 2)
        #expect(mom.roundsLed == 2)

        #expect(dad.roundsPlayed == 3)
        #expect(dad.best == 4)
        #expect(dad.roundsWon == 0)
        #expect(dad.results.last == Stats.RoundResult(points: nil, won: false))
        #expect(dad.points == [2, 4, 2])
    }

    @Test func lowScoreGamesFavorTheLowest() {
        let stats = stats(["Alex", "Mom"],
                          rounds: [complete(["Alex": 2, "Mom": 5]), complete(["Alex": 8, "Mom": 1])],
                          lowScoreWins: true)

        #expect(stats.bestRound == Stats.Record(player: "Mom", value: 1, round: 2))
        #expect(stats.players["Alex"]?.best == 2)
        #expect(stats.players.mapValues(\.roundsWon) == ["Alex": 1, "Mom": 1])
        #expect(stats.players.mapValues(\.roundsLed) == ["Alex": 1, "Mom": 1])
        #expect(stats.leadChanges == 1)
        #expect(stats.leadMargin == 4)
        #expect(stats.biggestLead == Stats.Record(player: "Mom", value: 4, round: 2))
        #expect(stats.hotStreak == nil)
    }

    @Test func theOpenRoundCountsTowardTotalsButNotRoundRecords() {
        let stats = stats(["Alex", "Mom"],
                          rounds: [complete(["Alex": 5, "Mom": 3]), open(["Alex": 0, "Mom": 10])])

        #expect(stats.completeRounds == 1)
        #expect(stats.bestRound == Stats.Record(player: "Alex", value: 5, round: 1))
        #expect(stats.players["Mom"]?.roundsWon == 0)
        #expect(stats.players["Mom"]?.results.count == 1)
        #expect(stats.leadChanges == 1)
        #expect(stats.leadMargin == 8)
        #expect(stats.biggestClimb == Stats.Climb(player: "Mom", fromRank: 1, toRank: 0))
    }

    @Test func aTieLeavesTheLeadWhereItWas() {
        let stats = stats(["Alex", "Mom"], rounds: [
            complete(["Alex": 5, "Mom": 3]),
            complete(["Alex": 0, "Mom": 2]),
            complete(["Alex": 1, "Mom": 0])
        ])

        #expect(stats.leadChanges == 0)
        #expect(stats.leadMargin == 1)
        // Both share first after the tied round
        #expect(stats.players.mapValues(\.roundsLed) == ["Alex": 3, "Mom": 1])
    }

    @Test func aTieForFirstHasNoMargin() {
        let stats = stats(["Alex", "Mom"], rounds: [complete(["Alex": 4, "Mom": 4])])

        #expect(stats.leadMargin == 0)
        #expect(stats.biggestLead == nil)
    }

    @Test func earlierPointsCanHoldTheFirstLead() {
        let stats = stats(["Alex", "Mom"],
                          startingPoints: ["Alex": 10],
                          rounds: [complete(["Alex": 0, "Mom": 12])])

        #expect(stats.leadChanges == 1)
        // The lead before any round isn't a round's record
        #expect(stats.biggestLead == Stats.Record(player: "Mom", value: 2, round: 1))
    }

    @Test func nobodyWinsARoundOfZeros() {
        let stats = stats(["Alex", "Mom"], rounds: [complete(["Alex": 0, "Mom": 0])])

        #expect(stats.players.mapValues(\.roundsWon) == ["Alex": 0, "Mom": 0])
        #expect(stats.bestRound == nil)
    }

    @Test func consistencyNeedsEnoughRoundsFromTwoPlayers() {
        let twoRounds = stats(["Alex", "Mom"], rounds: [
            complete(["Alex": 1, "Mom": 5]),
            complete(["Alex": 2, "Mom": 9])
        ])
        let oneQualifies = stats(["Alex", "Mom"], rounds: [
            complete(["Alex": 1, "Mom": 5]),
            complete(["Alex": 2]),
            complete(["Alex": 3, "Mom": 4])
        ])

        #expect(twoRounds.mostConsistent == nil)
        #expect(oneQualifies.mostConsistent == nil)
    }

    @Test func aStreakEndsWhenThePlayerSitsOut() {
        let stats = stats(["Alex", "Mom"], rounds: [
            complete(["Alex": 5, "Mom": 1]),
            complete(["Mom": 2]),
            complete(["Alex": 5, "Mom": 1]),
            complete(["Alex": 5, "Mom": 1])
        ])

        #expect(stats.hotStreak == Stats.Record(player: "Alex", value: 2, round: 3))
    }

    @Test func tiesGoToTheFirstToJoin() {
        let rounds = [complete(["Alex": 5, "Mom": 5]), complete(["Alex": 5, "Mom": 5])]

        #expect(stats(["Alex", "Mom"], rounds: rounds).bestRound?.player == "Alex")
        #expect(stats(["Mom", "Alex"], rounds: rounds).bestRound?.player == "Mom")
        #expect(stats(["Mom", "Alex"], rounds: rounds).hotStreak?.player == "Mom")
    }

    @Test func pointsFromUnlistedPlayersAreLeftOut() {
        let stats = stats(["Alex", "Mom"], rounds: [complete(["Alex": 2, "Mom": 1, "Guest": 50])])

        #expect(stats.players["Guest"] == nil)
        #expect(stats.bestRound == Stats.Record(player: "Alex", value: 2, round: 1))
        #expect(stats.leadMargin == 1)
    }

    @MainActor
    @Test func buildsFromAGame() throws {
        let container = try ModelContainer(for: Game.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let game = Game(name: "Test")
        container.mainContext.insert(game)
        let alex = game.addPlayer(with: "Alex", score: 4)
        let mom = game.addPlayer(with: "Mom")
        game.completeRound(with: [(alex, 1), (mom, 6)])
        game.completeRound(with: [(alex, 3), (mom, 2)])

        let stats = GameStats(game: game)

        #expect(stats.completeRounds == 2)
        // Alex's earlier 4 points held the lead until Mom's first round, then they finish tied
        #expect(stats.leadChanges == 1)
        #expect(stats.leadMargin == 0)
        #expect(stats.players[mom.persistentModelID]?.best == 6)
        #expect(stats.players[alex.persistentModelID]?.roundsWon == 1)
        #expect(stats.players[mom.persistentModelID]?.roundsWon == 1)
        #expect(stats.bestRound?.player == mom.persistentModelID)
    }
}
