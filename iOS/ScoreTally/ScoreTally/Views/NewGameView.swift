//
// NewGameView
// ScoreTally
//
// Created on 2026-10-16
//

import SwiftData
import SwiftUI

/// Sets up a game in one go: its name, how it's won and who's playing
struct NewGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// Handed the game once it's saved, so it can be opened
    let onCreate: (Game) -> Void

    @State private var name = ""
    @State private var lowScoreWins = false
    @State private var players = [NewPlayer]()
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case name
        case player(NewPlayer.ID)
    }

    /// A player to add once the game is created
    private struct NewPlayer: Identifiable {
        let id = UUID()
        var name = ""
        var color: PlayerColor
    }

    private var hasChanges: Bool {
        !name.trimmed.isEmpty || lowScoreWins || players.contains { !$0.name.trimmed.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(text: $name) {
                        Text(.createGamePlaceholder)
                    }
                    .focused($focus, equals: .name)
                    .submitLabel(.next)
                    .onSubmit(onSubmitName)
                    .accessibilityIdentifier("new-game-name")
                    Toggle(isOn: $lowScoreWins) {
                        Text(.lowScoreWinsEditLabel)
                    }
                    .accessibilityIdentifier("new-game-low-score-wins")
                }

                Section {
                    ForEach($players) { $player in
                        HStack(spacing: 12) {
                            PlayerColorButton(color: $player.color, name: player.name)
                            TextField(text: $player.name) {
                                Text(.createPlayerPlaceholder)
                            }
                            .focused($focus, equals: .player(player.id))
                            .submitLabel(.next)
                            .onSubmit {
                                onSubmitPlayer(player.id)
                            }
                        }
                    }
                    .onDelete { offsets in
                        players.remove(atOffsets: offsets)
                    }
                    Button(action: addPlayer) {
                        Label(.addPlayer, systemImage: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("new-game-add-player")
                } header: {
                    Text(.playersSectionTitle)
                } footer: {
                    Text(.newGamePlayersFooter)
                }
            }
            .navigationTitle(.createGameTitle)
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
                    ConfirmButton(title: .createGameButtonTitle, action: onCreateGame)
                        .keyboardShortcut("s", modifiers: .command)
                        .accessibilityIdentifier("create-game-button-title")
                        .disabled(name.trimmed.isEmpty)
                }
            }
            .interactiveDismissDisabled(hasChanges)
            .onAppear {
                focus = .name
            }
        }
    }

    private func addPlayer() {
        let player = NewPlayer(color: PlayerColor.firstUnused(by: players.map(\.color)))
        players.append(player)
        focus = .player(player.id)
    }

    /// Moves on to the first player, adding one if there are none yet
    private func onSubmitName() {
        if let first = players.first {
            focus = .player(first.id)
        } else {
            addPlayer()
        }
    }

    /// Moves on to the next player, adding one after the last unless it's still blank
    private func onSubmitPlayer(_ id: NewPlayer.ID) {
        guard let index = players.firstIndex(where: { $0.id == id }) else {
            return
        }
        if players.indices.contains(index + 1) {
            focus = .player(players[index + 1].id)
        } else if !players[index].name.trimmed.isEmpty {
            addPlayer()
        } else {
            focus = nil
        }
    }

    private func onCreateGame() {
        let game = Game(name: name.trimmed, lowScoreWins: lowScoreWins)
        // Inserted first so the players land in the context
        modelContext.insert(game)
        let start = Date.now
        for (index, player) in players.filter({ !$0.name.trimmed.isEmpty }).enumerated() {
            let newPlayer = game.addPlayer(with: player.name.trimmed, color: player.color)
            // Players made in one go can share a timestamp, so space them out to keep the order they were listed in
            newPlayer.creationDate = start.addingTimeInterval(Double(index) / 1000)
        }
        // Saving swaps the new game's temporary identifier for a permanent one before it can be selected
        try? modelContext.save()
        onCreate(game)
        dismiss()
    }
}

#if DEBUG
#Preview(traits: .sampleData) {
    NewGameView { _ in }
}
#endif
