//
// AddToScoreSheet
// ScoreTally
//
// Created on 2026-10-29
//

import SwiftUI

/// Adds any number of points to one player. It's a sheet rather than an alert so the number pad
/// can have a key above it for making the points negative.
struct AddToScoreSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let player: Player

    @State private var entry = ""
    // An index so the field can share the keyboard toolbar with the multi-player sheets
    @FocusState private var focusedIndex: Int?

    @ScaledMetric(relativeTo: .body) private var avatarSize = 28

    private var points: Int {
        entry.scoreValue ?? 0
    }

    init(for player: Player) {
        self.player = player
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        PlayerAvatar(player: player, size: avatarSize)
                        Text(player.name)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        pointsField
                    }
                } footer: {
                    Text(scoreChangeText)
                }
            }
            .navigationTitle(.addToScoreTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    ConfirmButton(title: .addToScoreButtonTitle, action: onAdd)
                        .keyboardShortcut(.defaultAction)
                        .accessibilityIdentifier("add-to-score-button-title")
                        .disabled(points == 0)
                }
            }
            .scoreEntryKeyboardToolbar(focusedIndex: $focusedIndex, count: 1) { _ in
                entry = entry.togglingScoreSign
            }
            .task {
                // Focusing while the sheet is still sliding up brings up the keyboard without its toolbar
                try? await Task.sleep(for: .milliseconds(450))
                focusedIndex = 0
            }
        }
    }

    private var pointsField: some View {
        TextField(text: Binding {
            entry
        } set: {
            entry = $0.sanitizedScoreEntry
        }) {
            Text(.addToScorePlaceholder)
        }
        .textFieldStyle(.roundedBorder)
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
        .keyboardType(.numberPad)
        .frame(maxWidth: 140)
        .focused($focusedIndex, equals: 0)
        .submitLabel(.done)
        .onSubmit(onAdd)
        .accessibilityInputLabels([player.name])
        .accessibilityIdentifier("add-to-score-input")
    }

    private var scoreChangeText: LocalizedStringResource {
        let oldScore = player.total.formatted(.number)
        let newScore = (player.total + points).formatted(.number)
        if points < 0 {
            return .scoreChangeSubtraction(oldScore, points.magnitude.formatted(.number), newScore)
        } else {
            return .scoreChangeAddition(oldScore, points.formatted(.number), newScore)
        }
    }

    private func onAdd() {
        guard points != 0 else { return }
        let points = points
        withAnimation {
            player.increment(by: points)
        }
        dismiss()
    }
}

#if DEBUG
import SwiftData

#Preview(traits: .sampleData) {
    @Previewable @Query var players: [Player]
    AddToScoreSheet(for: players.first!)
}
#endif
