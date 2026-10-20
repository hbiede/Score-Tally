//
// GameListViewCell
// ScoreTally
//
// Created on 7/5/24
//

import SwiftData
import SwiftUI

struct GameListViewCell: View {
    @Environment(\.modelContext) private var modelContext

    let game: Game
    /// Opens a game, such as a copy once it's saved
    let onSelect: (Game) -> Void

    @State private var showingEditPopover = false
    @State private var showingDuplicationPrompt = false
    @State private var duplicationPromptText = ""
    @State private var showingResetConfirmation = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(game.name)
                .font(.headline.weight(.semibold))

            let dateString = game.createdDate.formatted(date: .numeric, time: .omitted)
            if let winner = game.winner {
                Text(.winner(dateString, winner.name))
            } else {
                Text(dateString)
            }
        }
        .accessibilityIdentifier(game.name)
        .accessibilityHint(Text(.gameListItemA11YHint(game.playersByScore.map(\.name).formatted(.list(type: .and)))))
        .onKeyPress(keys: [.delete, .deleteForward]) { _ in
            onShowDeleteConfirmation()
            return .handled
        }
        // Not a destructive role, which would remove the row before the deletion is confirmed
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: onShowDeleteConfirmation) {
                Label(.deleteGameRightClickAction, systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Button(.editGameRightClickAction, action: onEdit)
                .accessibilityIdentifier("edit-game-right-click-action")
            Button(.deleteGameRightClickAction, role: .destructive, action: onShowDeleteConfirmation)
                .accessibilityIdentifier("delete-game-right-click-action")
            Button(.duplicateGameRightClickAction, action: onShowDuplicate)
                .accessibilityIdentifier("duplicate-game-right-click-action")
            Button(.resetGameRightClickAction, action: onShowResetConfirmation)
                .accessibilityIdentifier("reset-game-right-click-action")
                .disabled(!game.canReset)
        }
        .alert(.duplicateGameTitle, isPresented: $showingDuplicationPrompt) {
            TextField(text: $duplicationPromptText) {
                Text(.duplicateGamePlaceholder)
            }

            Button(.cancel, role: .cancel) {}
            Button(.duplicateGameButtonTitle) {
                onDuplicate(with: duplicationPromptText.trimmed)
            }
            .disabled(duplicationPromptText.trimmed.isEmpty)
        }
        .confirmationDialog(
            Text(.resetGameConfirmationTitle(game.name)),
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(.resetGameConfirmationButton, role: .destructive, action: onReset)
                .accessibilityIdentifier("reset-game-confirmation-button")
            Button(.cancel, role: .cancel) {}
        } message: {
            Text(.resetGameConfirmationMessage)
        }
        .confirmationDialog(
            Text(.deleteGameConfirmationTitle(game.name)),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(.deleteConfirmationButton, role: .destructive, action: onDelete)
                .accessibilityIdentifier("delete-game-confirmation-button")
            Button(.cancel, role: .cancel) {}
        } message: {
            Text(.deleteGameConfirmationMessage)
        }
        .sheet(isPresented: $showingEditPopover) {
            GameEditPopover(for: game)
                .presentationSizing(.form)
        }
    }

    private func onEdit() {
        showingEditPopover = true
    }

    private func onDelete() {
        withAnimation {
            game.delete()
        }
    }

    private func onShowDeleteConfirmation() {
        showingDeleteConfirmation = true
    }

    private func onDuplicate(with name: String) {
        guard let copy = game.duplicate(named: name) else {
            return
        }
        // Saving swaps the new game's temporary identifier for a permanent one before it can be selected
        try? modelContext.save()
        onSelect(copy)
    }

    private func onReset() {
        game.reset()
    }

    private func onShowResetConfirmation() {
        showingResetConfirmation = true
    }

    private func onShowDuplicate() {
        duplicationPromptText = ""
        showingDuplicationPrompt = true
    }
}
