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

    private let players: [Player]

    @State private var scores: [Int]

    private var newPlayerScores: [Player] {
        scores.enumerated().map { (index, score) in
            players[index] + score
        }
    }

    init(for players: [Player]) {
        self.players = players
        scores = players.map { _ in 0 }
    }

    var body: some View {
        Form {
            List(players.indices, id: \.self) { index in
                ViewThatFits {
                    HStack {
                        Text("\(players[index].name) \(getRanking(for: index))")
                            .frame(minWidth: 150, alignment: .leading)
                            .accessibilityIdentifier("player-\(index)")
                        TextField("add-to-score-placeholder", value: $scores[index], format: .number)
                            .padding(.trailing)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("player-input-\(index)")
                        if let changeString = getRankingChange(for: index) {
                            Text("\(changeString)")
                        }
                        if scores[index] < 0 {
                            Text("\(players[index].score.formatted(.number)) - \(scores[index].magnitude.formatted(.number)) = \((players[index].score + scores[index]).formatted(.number))")
                                .frame(minWidth: 150, alignment: .trailing)
                        } else {
                            Text("\(players[index].score.formatted(.number)) + \(scores[index].formatted(.number)) = \((players[index].score + scores[index]).formatted(.number))")
                                .frame(minWidth: 150, alignment: .trailing)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(players[index].name) \(getRanking(for: index))")
                                .font(.headline)
                                .frame(minWidth: 150, alignment: .leading)
                                .accessibilityIdentifier("player-\(index)")
                                .padding(.top)
                            Text(getRankingChange(for: index) ?? "")
                        }
                        VStack {
                            TextField("add-to-score-placeholder", value: $scores[index], format: .number)
                                .textFieldStyle(.roundedBorder)
                            if scores[index] < 0 {
                                Text("\(players[index].score.formatted(.number)) - \(scores[index].magnitude.formatted(.number)) = \((players[index].score + scores[index]).formatted(.number))")
                                    .font(.callout)
                            } else {
                                Text("\(players[index].score.formatted(.number)) + \(scores[index].formatted(.number)) = \((players[index].score + scores[index]).formatted(.number))")
                                    .font(.callout)
                            }
                        }
                    }
                }
            }
            Section {
                Button("save-round-button-title", action: onSave)
                    .keyboardShortcut("s", modifiers: .command)
                    .accessibilityIdentifier("save-round-button-title")
                    .disabled(scores.allSatisfy { $0 == 0 })
                Button("cancel", role: .cancel, action: onSave)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("cancel")
            }
        }
    }

    private func getRanking(for index: Int, showLossOfPlace: Bool = false) -> String {
        if let game = players[index].game,
           showLossOfPlace || players[index].score > 0 || game.lowScoreWins {
            return getRankingEmoji(for: game.ranking(for: players[index]),
                                   showLossOfPlace: showLossOfPlace)
        }
        return ""
    }

    private func getRankingChange(for index: Int) -> String? {
        if scores.allSatisfy({ $0 == scores.first! }) ||
        (players[index].score == 0 &&
         newPlayerScores[index].score == 0 &&
         !(players[index].game?.lowScoreWins ?? false)) {

            return nil
        }

        let current = getRanking(for: index, showLossOfPlace: true)
        let newRanking = Game.ranking(for: newPlayerScores[index],
                                      in: newPlayerScores,
                                      with: players.first!.game?.lowScoreWins ?? false)
        let newRankingString = getRankingEmoji(for: newRanking, showLossOfPlace: true)

        if current == newRankingString {
            return nil
        }

        return String(format: NSLocalizedString("rank-change-tooltip-%@-%@", comment: "A string to indicate change in rank"),
                      current, newRankingString)
    }

    private func onSave() {
        players.enumerated().forEach { (index, player) in
            player.increment(by: scores[index])
        }
        dismiss()
    }
}

#if DEBUG
import SwiftData

#Preview(traits: .sampleData) {
    @Previewable @Query var games: [Game] = [Game]()
    ScoreRoundPopover(for: games.first!.players)
}
#endif
