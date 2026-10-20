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

    private var hasChanges: Bool {
        name.trimmed != game.name || lowScoreWins != game.lowScoreWins
    }

    init(for game: Game) {
        self.game = game

        self.name = game.name
        self.lowScoreWins = game.lowScoreWins
    }

    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Text(.gameNameEditLabel)
                    TextField(text: $name) {
                        Text(.gameNameEditPlaceholder)
                    }
                    .textFieldStyle(.roundedBorder)
                }
                Toggle(isOn: $lowScoreWins) {
                    Text(.lowScoreWinsEditLabel)
                }
            }
            .navigationTitle(.editGameTitle)
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
                    ConfirmButton(title: .saveGameButtonTitle, action: onSave)
                        .keyboardShortcut("s", modifiers: .command)
                        .accessibilityIdentifier("save-game-button-title")
                        .disabled(name.trimmed.isEmpty || !hasChanges)
                }
            }
            .interactiveDismissDisabled(hasChanges)
        }
    }

    private func onSave() {
        game.name = name.trimmed
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
