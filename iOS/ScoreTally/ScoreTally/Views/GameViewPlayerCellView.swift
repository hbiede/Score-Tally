//
// GameViewPlayerCellView
// ScoreTally 
//
// Created on 7/5/24
//

import SwiftUI

struct GameViewPlayerCellView: View {
    @Environment(\.modelContext) private var modelContext

    private var player: Player

    @State private var showingCustomIncrementMenu = false
    @State private var addingScore = 0

    @State private var showingEditPrompt = false
    @State private var editingPlayerText = ""

    init(for player: Player) {
        self.player = player
    }

    var body: some View {
        Button(action: {}) {
            ViewThatFits(in: .horizontal) {
                // Expanded single-line
                HStack {
                    Text(player.name)
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                        .padding(.all)
                    if player.score > 0 || player.game?.lowScoreWins == true,
                       let rank = player.game?.ranking(for: player),
                       rank >= 0 && rank < 3 {
                        Text(getRankingEmoji(for: rank))
                            .font(.title2)
                    }
                    Text(player.score.formatted(.number))
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(.trailing)
                }

                // Medium with wrap
                VStack {
                    HStack {
                        Text(player.name)
                            .font(.title)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.all)
                        if player.score > 0 || player.game?.lowScoreWins == true,
                           let rank = player.game?.ranking(for: player),
                           rank >= 0 && rank < 3 {
                            Text(getRankingEmoji(for: rank))
                                .font(.title2)
                        }
                    }
                    Text(player.score.formatted(.number))
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(.trailing)
                        .padding(.bottom)
                }

                // Compact with no ranking
                VStack {
                    Text(player.name)
                        .font(.title)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.all)
                    Text(player.score.formatted(.number))
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(.trailing)
                        .padding(.bottom)
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .simultaneousGesture(
            LongPressGesture()
                .onEnded { _ in
                    onEdit()
                }
        )
        .highPriorityGesture(
            TapGesture()
                .onEnded { _ in
                    onPress()
                }
        )
        .contextMenu {
            Section {
                Button("delete-player-right-click-action") {
                    withAnimation {
                        if let players = player.game?._players,
                           let index = players.firstIndex(of: player) {
                            player.game!._players.remove(at: index)
                        }
                        modelContext.delete(player)
                    }
                }
                Button("edit-player-right-click-action") {
                    onEdit()
                }
            }

            Menu("increment-right-click-section-title", content: {
                incrementMenuButton(for: 1)
                incrementMenuButton(for: 5)
                incrementMenuButton(for: 10)
                incrementMenuButton(for: 25)
                incrementMenuButton(for: 100)
                Button("increment-by-custom-amount-right-click-button") {
                    addCustomScore()
                }
            }, primaryAction: {
                player.increment()
            })
            Button("reset-score-right-click-button") {
                player.score = 0
            }
        }
        .alert("edit-player-title", isPresented: $showingEditPrompt) {
            TextField("edit-player-placeholder", text: $editingPlayerText)

            Button("cancel", role: .cancel) {
                showingEditPrompt = false
            }
            Button("edit-player-button-title") {
                withAnimation {
                    player.name = editingPlayerText
                }
            }
        }
        .alert("add-to-score-title", isPresented: $showingCustomIncrementMenu) {
            TextField("add-to-score-placeholder", value: $addingScore, format: .number)

            Button("cancel", role: .cancel) {
                showingCustomIncrementMenu = false
            }
            Button("add-to-score-button-title") {
                withAnimation {
                    player.score += addingScore
                }
            }
        }
        .accessibilityIdentifier(player.name)
    }

    private func addCustomScore() {
        showingCustomIncrementMenu = true
        addingScore = 0
    }

    private func incrementMenuButton(for increment: Int) -> some View {
        Button(String(format: NSLocalizedString("increment-by-%@-right-click-button",
                                                comment: "Right click action to increment player score"),
                      increment)) {
            player.increment(by: increment)
        }
    }

    private func onEdit() {
        editingPlayerText = player.name
        showingEditPrompt = true
    }

    private func onPress() {
        player.increment()
    }
}

#if DEBUG
import SwiftData

#Preview(traits: .sampleData) {
    @Previewable @Query var players: [Player] = [Player]()
    GameViewPlayerCellView(for: players.first!)
}
#endif
