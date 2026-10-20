//
// ScoreRoundPopover
// ScoreTally
//
// Created on 7/5/24
//

import Foundation
import SwiftUI

struct ScoreRoundPopover: View {
    @Environment(\.dismiss) private var dismiss

    private let game: Game
    private let lowScoreWins: Bool

    // Kept from when the sheet opened, so re-sorting or a sync can't shift the rows under the points being typed
    @State private var players: [Player]
    @State private var scores: [Int]
    @FocusState private var focusedIndex: Int?

    private var hasChanges: Bool {
        scores.contains { $0 != 0 }
    }

    private var currentStandings: Standings {
        Standings(scores: players.map(\.total), lowScoreWins: lowScoreWins)
    }

    private var newStandings: Standings {
        Standings(scores: zip(players, scores).map { $0.total + $1 }, lowScoreWins: lowScoreWins)
    }

    /// Scores a round for `players`, listed in the order given so they match the game's grid
    init(for game: Game, players: [Player]) {
        self.game = game
        lowScoreWins = game.lowScoreWins
        _players = State(initialValue: players)
        _scores = State(initialValue: players.map { _ in 0 })
    }

    var body: some View {
        let current = currentStandings
        let updated = newStandings

        NavigationStack {
            Form {
                ForEach(players.indices, id: \.self) { index in
                    let ranking = current.place(of: players[index].total).rankingEmoji()
                    let rankingChange = getRankingChange(for: index, from: current, to: updated)

                    HStack {
                        VStack(alignment: .leading) {
                            // Separate texts keep the medal after the name in right-to-left languages,
                            // where one string would put it before a Latin name
                            HStack(spacing: 4) {
                                Text(players[index].name)
                                if !ranking.isEmpty {
                                    Text(verbatim: ranking)
                                }
                            }
                            .font(.headline)
                            .frame(minWidth: 150, alignment: .leading)
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("player-\(index)")
                            .padding(.top)
                            if let rankingChange {
                                Text(rankingChange)
                            }
                        }
                        VStack {
                            scoreField(for: index)
                            Text(getScoreChangeText(for: players[index], with: scores[index]))
                        }
                    }
                }
            }
            .navigationTitle(.scoreRound)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    DiscardCloseButton(hasChanges: hasChanges) {
                        dismiss()
                    }
                        .keyboardShortcut(.cancelAction)
                        .accessibilityIdentifier("cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    ConfirmButton(title: .saveRoundButtonTitle, action: onSave)
                        .keyboardShortcut("s", modifiers: .command)
                        .accessibilityIdentifier("save-round-button-title")
                }
            }
            .interactiveDismissDisabled(hasChanges)
        }
    }

    private func scoreField(for index: Int) -> some View {
        TextField(value: $scores[index], format: .number) {
            Text(.addToScorePlaceholder)
        }
        .textFieldStyle(.roundedBorder)
        .keyboardType(.numbersAndPunctuation)
        .focused($focusedIndex, equals: index)
        .submitLabel(index < players.count - 1 ? .next : .done)
        .onSubmit {
            focusedIndex = index < players.count - 1 ? index + 1 : nil
        }
        // Every field shares one placeholder, so Voice Control would have no way to tell them apart
        .accessibilityInputLabels([players[index].name])
        .accessibilityIdentifier("player-input-\(index)")
    }

    private func getRankingChange(for index: Int,
                                  from current: Standings,
                                  to new: Standings) -> LocalizedStringResource? {
        let currentRanking = current.place(of: players[index].total).rankingEmoji(showLossOfPlace: true)
        let newRanking = new.place(of: players[index].total + scores[index]).rankingEmoji(showLossOfPlace: true)

        if currentRanking == newRanking {
            return nil
        }

        return .rankChangeTooltip(currentRanking, newRanking)
    }

    private func getScoreChangeText(for player: Player, with score: Int) -> LocalizedStringResource {
        let oldScore = player.total.formatted(.number)
        let newScore = (player.total + score).formatted(.number)
        if score < 0 {
            return .scoreChangeSubtraction(oldScore, score.magnitude.formatted(.number), newScore)
        } else {
            return .scoreChangeAddition(oldScore, score.formatted(.number), newScore)
        }
    }

    private func onSave() {
        // A sync can delete a player while the sheet is open, so skip any that are gone.
        game.completeRound(with: zip(players, scores).filter { !$0.0.isDeleted })
        dismiss()
    }
}

#if DEBUG
import SwiftData

#Preview(traits: .sampleData) {
    @Previewable @Query var games: [Game] = [Game]()
    ScoreRoundPopover(for: games.first!, players: games.first!.players)
}
#endif
