//
// PlayerEditView
// ScoreTally
//
// Created on 2026-10-16
//

import SwiftData
import SwiftUI

/// Names a new player or renames one, and picks their color
struct PlayerEditView: View {
    @Environment(\.dismiss) private var dismiss

    /// The game to add to, when adding a player
    private let game: Game?
    /// The player to change, when editing one
    private let player: Player?
    private let originalName: String
    private let originalColor: PlayerColor

    @State private var name: String
    @State private var color: PlayerColor
    @FocusState private var isNameFocused: Bool

    @ScaledMetric(relativeTo: .largeTitle) private var avatarSize = 64

    private var isAdding: Bool {
        player == nil
    }

    private var hasChanges: Bool {
        name != originalName || color != originalColor
    }

    private var canSave: Bool {
        !name.trimmed.isEmpty && (isAdding || hasChanges)
    }

    /// Adds a player to `game`, starting from the next free color
    init(adding game: Game) {
        self.game = game
        player = nil
        originalName = ""
        originalColor = game.nextColor
        _name = State(initialValue: "")
        _color = State(initialValue: originalColor)
    }

    /// Changes `player`'s name and color
    init(editing player: Player) {
        game = nil
        self.player = player
        originalName = player.name
        originalColor = player.color
        _name = State(initialValue: player.name)
        _color = State(initialValue: player.color)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PlayerAvatar(initials: Player.initials(for: name.trimmed), color: color.color, size: avatarSize)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)

                Section {
                    TextField(text: $name) {
                        Text(isAdding ? .createPlayerPlaceholder : .editPlayerPlaceholder)
                    }
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit(onSave)
                    .accessibilityIdentifier("player-name")
                }

                Section {
                    PlayerColorPicker(selection: $color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                } header: {
                    Text(.playerColorLabel)
                }
            }
            .navigationTitle(isAdding ? .createPlayerTitle : .editPlayerTitle)
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
                    ConfirmButton(title: isAdding ? .createPlayerButtonTitle : .editPlayerButtonTitle,
                                  action: onSave)
                        .keyboardShortcut("s", modifiers: .command)
                        .accessibilityIdentifier(isAdding ? "create-player-button-title" : "edit-player-button-title")
                        .disabled(!canSave)
                }
            }
            .interactiveDismissDisabled(hasChanges)
            .onAppear {
                isNameFocused = true
            }
        }
    }

    private func onSave() {
        guard canSave else {
            return
        }
        let name = name.trimmed
        if let player {
            withAnimation {
                player.name = name
                // Only stored when changed, so an older player's join-order color isn't pinned for no reason
                if color != player.color {
                    player.storedColor = color.rawValue
                }
            }
        } else {
            game?.addPlayer(with: name, color: color)
        }
        dismiss()
    }
}

#if DEBUG
#Preview("Add", traits: .sampleData) {
    @Previewable @Query var games: [Game] = [Game]()
    PlayerEditView(adding: games.first!)
}

#Preview("Edit", traits: .sampleData) {
    @Previewable @Query var players: [Player] = [Player]()
    PlayerEditView(editing: players.first!)
}
#endif
