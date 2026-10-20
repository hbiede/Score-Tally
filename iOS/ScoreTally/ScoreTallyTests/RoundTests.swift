//
// RoundTests
// ScoreTallyTests
//
// Created on 2026-10-09
//

import Foundation
import SwiftData
import Testing
@testable import ScoreTally

@MainActor
struct RoundTests {
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

    @Test func completingARoundRecordsEveryPlayer() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        game.completeRound(with: zip(players, [5, 0]))

        let round = try #require(game.rounds.first)
        #expect(game.rounds.count == 1)
        #expect(round.isComplete)
        #expect(round.points(for: players[0]) == 5)
        #expect(round.points(for: players[1]) == 0)
        #expect(players.map(\.score) == [5, 0])
        #expect(game.openRound == nil)
    }

    @Test func completingARoundOfZerosClosesIt() {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        players[0].increment(by: 2)
        game.completeRound(with: zip(players, [0, 0]))

        #expect(game.rounds.count == 1)
        #expect(game.openRound == nil)
        #expect(game.rounds[0].points(for: players[1]) == 0)
    }

    @Test func entriesFromAnotherDeviceAddUp() throws {
        let (game, players) = makeGame(players: ["Alex"])
        let alex = players[0]

        alex.increment()
        // Another device added its own entry to the round, and its score lost the sync conflict
        let round = try #require(game.openRound)
        let synced = ScoreEntry(points: 2)
        context.insert(synced)
        alex.storedEntries?.append(synced)
        round.storedEntries?.append(synced)

        #expect(round.points(for: alex) == 3)
        #expect(alex.total == 3)
        #expect(alex.unrecordedPoints == 0)
    }

    @Test func totalTrustsEntriesWhenAnotherDevicesScoreWins() {
        let (game, players) = makeGame(players: ["Alex"])
        let alex = players[0]

        game.completeRound(with: zip(players, [5]))
        alex.increment()
        // The other device's +2 synced as an entry, and its score and recorded points replaced these
        let synced = ScoreEntry(points: 2)
        context.insert(synced)
        alex.storedEntries?.append(synced)
        game.openRound?.storedEntries?.append(synced)
        alex.score = 7
        alex.recordedPoints = 7

        #expect(alex.total == 8)
        #expect(alex.unrecordedPoints == 0)
        #expect(game.runningTotals(for: alex) == [5, 8])
    }

    @Test func olderVersionsChangesStayUnrecorded() {
        let (game, players) = makeGame(players: ["Alex"])
        let alex = players[0]

        game.completeRound(with: zip(players, [3]))
        // Older versions only change the score
        alex.score += 5

        #expect(alex.unrecordedPoints == 5)
        #expect(alex.total == 8)
    }

    @Test func playersFromBeforeRecordedPointsKeepTheirScore() {
        let (game, players) = makeGame(players: ["Alex"])
        let alex = players[0]

        game.completeRound(with: zip(players, [3]))
        alex.recordedPoints = nil
        alex.score = 4

        #expect(alex.total == 4)
        #expect(alex.unrecordedPoints == 1)
    }

    @Test func scoringMergesOtherOpenRounds() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        // One device left a round open while another completed a later one
        let stale = Round(createdDate: .now.addingTimeInterval(-120))
        context.insert(stale)
        game.storedRounds?.append(stale)
        players[0].increment(by: 2, in: stale)
        let completed = Round(createdDate: .now.addingTimeInterval(-60))
        context.insert(completed)
        game.storedRounds?.append(completed)
        players[1].increment(by: 3, in: completed)
        completed.isComplete = true

        game.completeRound(with: zip(players, [1, 1]))
        try context.save()

        #expect(game.rounds.count == 2)
        #expect(game.rounds.allSatisfy { $0.isComplete })
        #expect(game.rounds[1].points(for: players[0]) == 3)
        #expect(game.rounds[1].points(for: players[1]) == 1)
        #expect(players.map(\.total) == [3, 4])
        #expect(try context.fetchCount(FetchDescriptor<Round>()) == 2)
    }

    @Test func incrementsCollectInTheOpenRound() {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        players[0].increment()
        players[0].increment(by: 4)
        players[1].increment(by: 2)

        #expect(game.rounds.count == 1)
        #expect(game.openRound?.points(for: players[0]) == 5)
        #expect(game.openRound?.points(for: players[1]) == 2)
    }

    @Test func incrementsAndScoringShareARound() {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        players[0].increment(by: 2)
        game.completeRound(with: zip(players, [3, 4]))

        #expect(game.rounds.count == 1)
        #expect(game.rounds[0].points(for: players[0]) == 5)
        #expect(game.rounds[0].points(for: players[1]) == 4)
    }

    @Test func incrementsAfterACompletedRoundStartANewOne() {
        let (game, players) = makeGame(players: ["Alex"])

        game.completeRound(with: zip(players, [3]))
        players[0].increment()

        #expect(game.rounds.count == 2)
        #expect(game.rounds[1].isComplete == false)
        #expect(game.rounds[1].points(for: players[0]) == 1)
    }

    @Test func zeroIncrementDoesNotStartARound() {
        let (game, players) = makeGame(players: ["Alex"])

        players[0].increment(by: 0)

        #expect(game.rounds.isEmpty)
    }

    @Test func playersMissingFromARoundHaveNoEntry() {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        game.completeRound(with: zip(players.prefix(1), [3]))

        #expect(game.rounds[0].points(for: players[1]) == nil)
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

    @Test func scoresWithoutRoundsAreUnrecorded() {
        let game = Game(name: "Test")
        context.insert(game)
        let player = game.addPlayer(with: "Alex", score: 10)

        player.increment(by: 3)

        #expect(player.score == 13)
        #expect(player.unrecordedPoints == 10)
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

    @Test func repeatedIncrementsShareOneEntry() {
        let (game, players) = makeGame(players: ["Alex"])

        players[0].increment()
        players[0].increment()
        players[0].increment(by: -1)

        #expect(game.openRound?.storedEntries?.count == 1)
        #expect(game.openRound?.points(for: players[0]) == 1)
    }

    @Test func negativeIncrementsAreRecorded() {
        let (game, players) = makeGame(players: ["Alex"])

        players[0].increment(by: -3)

        #expect(players[0].score == -3)
        #expect(game.openRound?.points(for: players[0]) == -3)
    }

    @Test func resettingAZeroScoreDoesNotStartARound() {
        let (game, players) = makeGame(players: ["Alex"])

        players[0].resetScore()

        #expect(game.rounds.isEmpty)
    }

    @Test func playersJoiningLateHaveNoEarlierEntries() {
        let (game, players) = makeGame(players: ["Alex"])

        game.completeRound(with: zip(players, [3]))
        let mom = game.addPlayer(with: "Mom")
        game.completeRound(with: [(players[0], 1), (mom, 4)])

        #expect(game.rounds[0].points(for: mom) == nil)
        #expect(game.rounds[1].points(for: mom) == 4)
    }

    @Test func playersWithoutAGameOnlyKeepATotal() throws {
        let player = Player(name: "Alex")
        context.insert(player)

        player.increment(by: 2)

        #expect(player.score == 2)
        #expect(player.storedEntries?.isEmpty ?? true)
        #expect(player.unrecordedPoints == 2)
        #expect(try context.fetchCount(FetchDescriptor<Round>()) == 0)
    }

    // CloudKit doesn't keep to-many order, so rounds must sort by date
    @Test func roundsAreOrderedByDateNotStorage() {
        let game = Game(name: "Test")
        context.insert(game)
        let later = Round(createdDate: Date(timeIntervalSince1970: 200))
        let earlier = Round(createdDate: Date(timeIntervalSince1970: 100))
        context.insert(later)
        context.insert(earlier)
        game.storedRounds?.append(contentsOf: [later, earlier])

        #expect(game.rounds == [earlier, later])
        #expect(game.openRound == later)
    }

    // Two devices can each leave a round open; only the latest one keeps collecting points
    @Test func onlyTheLatestRoundCanBeOpen() {
        let (game, players) = makeGame(players: ["Alex"])
        let stale = Round(createdDate: Date(timeIntervalSince1970: 100))
        let completed = Round(createdDate: Date(timeIntervalSince1970: 200))
        completed.isComplete = true
        context.insert(stale)
        context.insert(completed)
        game.storedRounds?.append(contentsOf: [stale, completed])

        players[0].increment()

        #expect(game.rounds.count == 3)
        #expect(game.rounds.last?.points(for: players[0]) == 1)
        #expect(stale.points(for: players[0]) == nil)
    }

    @Test func roundsBelongToTheirGame() {
        let (first, firstPlayers) = makeGame(players: ["Alex"])
        let (second, secondPlayers) = makeGame(players: ["Mom"])

        first.completeRound(with: zip(firstPlayers, [3]))
        secondPlayers[0].increment()

        #expect(first.rounds.count == 1)
        #expect(first.openRound == nil)
        #expect(second.rounds.count == 1)
        #expect(second.openRound?.points(for: secondPlayers[0]) == 1)
    }

    @Test func roundsSurviveSavingAndRefetching() throws {
        let (game, players) = makeGame(players: ["Alex", "Mom"])

        game.completeRound(with: zip(players, [3, 4]))
        players[0].increment()
        try context.save()

        let fresh = ModelContext(container)
        let fetched = try #require(try fresh.fetch(FetchDescriptor<Game>()).first)
        let alex = try #require(fetched.players.first { $0.name == "Alex" })
        let mom = try #require(fetched.players.first { $0.name == "Mom" })
        #expect(fetched.rounds.count == 2)
        #expect(fetched.rounds[0].isComplete)
        #expect(fetched.rounds[0].points(for: alex) == 3)
        #expect(fetched.rounds[0].points(for: mom) == 4)
        #expect(fetched.openRound?.points(for: alex) == 1)
        #expect(fetched.openRound?.points(for: mom) == nil)
        #expect(alex.unrecordedPoints == 0)
    }

    @Test func roundsAddUpToTheScoreAfterMixedPlay() {
        let (game, players) = makeGame(players: ["Alex", "Mom", "Dad"])

        players[0].increment()
        game.completeRound(with: zip(players, [3, 0, -2]))
        players[1].increment(by: 10)
        players[2].increment(by: -1)
        game.completeRound(with: zip(players, [1, 1, 1]))
        players[1].resetScore()
        players[0].increment(by: 5)

        for player in players {
            let roundTotal = game.rounds.compactMap { $0.points(for: player) }.reduce(0, +)
            #expect(roundTotal == player.score)
            #expect(player.unrecordedPoints == 0)
        }
        #expect(players.map(\.score) == [10, 0, -2])
        #expect(game.rounds.count == 3)
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
