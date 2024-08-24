//
// GameListViewCell
// ScoreTally 
//
// Created on 7/5/24
//

import SwiftUI

struct GameListViewCell: View {
    @Environment(\.modelContext) private var modelContext

    let game: Game

    @State private var showingEditPopover = false
    @State private var showingDuplicationPrompt = false
    @State private var duplicationPromptText = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text(game.name)
                .font(.headline.weight(.semibold))

            let dateString = game.createdDate.formatted(date: .numeric, time: .omitted)
            if let winner = game.winner,
               // Only show if there is a clear winner
               game.players.allSatisfy({ $0 == winner || winner.score != $0.score }) &&
                (game.lowScoreWins
                    // Show if it is a low-score winner and someone has a score
                    ? game.players.contains { $0.score > 0 }
                    // Show if there is a high-score winner
                    : winner.score > 0) {
                Text("\(dateString) - Winner: \(winner.name)")
            } else {
                Text(dateString)
            }
        }
        .accessibilityIdentifier(game.name)
        .accessibilityHint(
            String(format: NSLocalizedString("game-list-item-a11y-hint-%@",
                                             comment: "A11y hint for a game on the main game-selection screen"),
                   game.sortedPlayers.map(\.name).formatted(.list(type: .and)))
        )
        .onKeyPress(keys: [.delete, .deleteForward]) { _ in
            onDelete()
            return .handled
        }
        .contextMenu {
            Button("edit-game-right-click-action", action: onEdit)
                .accessibilityIdentifier("edit-game-right-click-action")
            Button("delete-game-right-click-action", action: onDelete)
                .accessibilityIdentifier("delete-game-right-click-action")
            Button("duplicate-game-right-click-action", action: onShowDuplicate)
                .accessibilityIdentifier("duplicate-game-right-click-action")
            Button("reset-game-right-click-action", action: onReset)
                .accessibilityIdentifier("reset-game-right-click-action")
        }
        .alert("duplicate-game-title", isPresented: $showingDuplicationPrompt) {
            TextField("duplicate-game-placeholder", text: $duplicationPromptText)

            Button("cancel", role: .cancel) {
                cancelCreation()
            }
            Button("duplicate-game-button-title") {
                onDuplicate(with: duplicationPromptText)
            }
            .disabled(duplicationPromptText.isEmpty)
        }
        .fullScreenCover(isPresented: $showingEditPopover, onDismiss: {
            showingEditPopover = false
        }, content: {
            GameEditPopover(for: game)
                .presentationCompactAdaptation(.fullScreenCover)
        })
    }

    private func cancelCreation() {
        showingDuplicationPrompt = false
    }

    private func onEdit() {
            showingEditPopover = true
    }

    private func onDelete() {
        withAnimation {
            game.players.forEach { modelContext.delete($0) }

            modelContext.delete(game)
        }
    }

    private func onDuplicate(with name: String) {
        let newGame = Game(name: name)

        let newList = game.players.map { Player(name: $0.name, score: $0.score) }
        newGame.storedPlayerList = newList
        newList.forEach { modelContext.insert($0) }

        modelContext.insert(newGame)
    }

    private func onReset() {
        game.players.forEach { $0.score = 0 }
    }

    private func onShowDuplicate() {
        duplicationPromptText = ""
        showingDuplicationPrompt = true
    }
}
