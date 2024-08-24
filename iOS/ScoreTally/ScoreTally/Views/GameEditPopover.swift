//
// GameEditPopover
// ScoreTally 
//
// Created on 2024-08-23
//

import SwiftUI

struct GameEditPopover: View {
    @Environment(\.dismiss) private var dismiss

    private var game: Game

    @State var lowScoreWins: Bool
    @State var name: String

    init(for game: Game) {
        self.game = game

        self.name = game.name
        self.lowScoreWins = game.lowScoreWins
    }

    var body: some View {
        Form {
            HStack {
                Text("game-name-edit-label")
                TextField("game-name-edit-placeholder", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Toggle("low-score-wins-edit-label", isOn: $lowScoreWins)
            }

            Section {
                Button("save-game-button-title", action: onSave)
                    .keyboardShortcut("s", modifiers: .command)
                    .accessibilityIdentifier("save-game-button-title")
                Button("cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("cancel")
            }
        }
    }

    private func onCancel() {
        dismiss()
    }

    private func onSave() {
        game.name = name
        game.lowScoreWins = lowScoreWins
        dismiss()
    }
}
#if DEBUG
import SwiftData

#Preview(traits: .sampleData) {
    @Previewable @Query var games: [Game] = [Game]()
    GameEditPopover(for: games.first!)
}
#endif
