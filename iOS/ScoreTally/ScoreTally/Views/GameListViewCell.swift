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

    @State private var showDuplicationPrompt = false
    @State private var duplicationPromptText = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text(game.name)
                .font(.headline.weight(.semibold))
            Text("\(game.createdDate, format: Date.FormatStyle(date: .numeric, time: .omitted))")
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
            Button("delete-game-right-click-action", action: onDelete)
                .accessibilityIdentifier("delete-game-right-click-action")
            Button("duplicate-game-right-click-action", action: onShowDuplicate)
                .accessibilityIdentifier("duplicate-game-right-click-action")
            Button("reset-game-right-click-action", action: onReset)
                .accessibilityIdentifier("reset-game-right-click-action")
        }
        .alert("duplicate-game-title", isPresented: $showDuplicationPrompt) {
            TextField("duplicate-game-placeholder", text: $duplicationPromptText)

            Button("cancel", role: .cancel) {
                cancelCreation()
            }
            Button("duplicate-game-button-title") {
                onDuplicate(with: duplicationPromptText)
            }
            .disabled(duplicationPromptText.isEmpty)
        }
    }

    private func cancelCreation() {
        showDuplicationPrompt = false
    }

    private func onDelete() {
        withAnimation {
            modelContext.delete(game)
        }
    }

    private func onDuplicate(with name: String) {
        let newGame = Game(name: name)

        newGame._players = game.players.map { Player(name: $0.name, score: $0.score) }
        newGame._players.forEach{ modelContext.insert($0) }

        modelContext.insert(newGame)
    }

    private func onReset() {
        game.players.forEach{ $0.score = 0 }
    }

    private func onShowDuplicate() {
        duplicationPromptText = ""
        showDuplicationPrompt = true
    }
}
