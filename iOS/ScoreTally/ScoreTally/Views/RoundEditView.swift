//
// RoundEditView
// ScoreTally
//
// Created on 2026-10-16
//

import SwiftData
import SwiftUI

/// Fixes the points in a round that's already been scored, or deletes it
struct RoundEditView: View {
    @Environment(\.dismiss) private var dismiss

    private let game: Game
    private let round: Round
    private let number: Int
    private let original: [Int?]

    // Kept from when the sheet opened, so a sync can't shift the rows under the points being typed
    @State private var players: [Player]
    @State private var points: [Int?]
    @State private var roundPendingDeletion: NumberedRound?
    @FocusState private var focusedIndex: Int?

    @ScaledMetric(relativeTo: .body) private var avatarSize = 28

    private var hasChanges: Bool {
        points != original
    }

    init(round: Round, number: Int, in game: Game) {
        self.game = game
        self.round = round
        self.number = number
        let players = game.players
        let original = players.map { round.points(for: $0) }
        self.original = original
        _players = State(initialValue: players)
        _points = State(initialValue: original)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(players.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            PlayerAvatar(player: players[index], size: avatarSize)
                            Text(players[index].name)
                                .lineLimit(2)
                            Spacer(minLength: 8)
                            pointsField(for: index)
                        }
                    }
                } footer: {
                    Text(.roundEditFooter)
                }

                Section {
                    Button(role: .destructive) {
                        roundPendingDeletion = NumberedRound(round: round, number: number)
                    } label: {
                        Label(.deleteRound, systemImage: "trash")
                    }
                    // Otherwise the icon takes the accent color while the title is red
                    .tint(.red)
                    .accessibilityIdentifier("delete-round")
                    .deleteRoundConfirmation($roundPendingDeletion) { _ in
                        onDelete()
                    }
                }
            }
            .navigationTitle(Text(.roundA11YLabel(number)))
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
                        .disabled(!hasChanges)
                }
            }
            .interactiveDismissDisabled(hasChanges)
        }
    }

    private func pointsField(for index: Int) -> some View {
        TextField(value: $points[index], format: .number, prompt: Text(.roundEditNotPlayedPlaceholder)) {
            Text(players[index].name)
        }
        // Bordered like the Score Round sheet's fields, so the points read as editable rather than as plain values
        .textFieldStyle(.roundedBorder)
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
        .keyboardType(.numbersAndPunctuation)
        .frame(maxWidth: 100)
        .focused($focusedIndex, equals: index)
        .submitLabel(index < players.count - 1 ? .next : .done)
        .onSubmit {
            focusedIndex = index < players.count - 1 ? index + 1 : nil
        }
        .accessibilityIdentifier("round-input-\(index)")
    }

    private func onSave() {
        // A sync can delete a player while the sheet is open, so skip any that are gone
        let changes = zip(players, points).enumerated()
            .filter { index, change in !change.0.isDeleted && change.1 != original[index] }
            .map(\.element)
        withAnimation {
            game.setPoints(changes, in: round)
        }
        dismiss()
    }

    private func onDelete() {
        withAnimation {
            game.deleteRound(round)
        }
        dismiss()
    }
}

#if DEBUG
#Preview(traits: .sampleData) {
    @Previewable @Query(filter: #Predicate<Game> { $0.name == "Family Game Night" }) var games: [Game]
    RoundEditView(round: games.first!.rounds.first!, number: 1, in: games.first!)
}
#endif
