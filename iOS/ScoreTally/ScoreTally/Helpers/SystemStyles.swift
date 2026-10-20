//
// SystemStyles
// ScoreTally
//
// Created on 2026-10-09
//

import SwiftUI

/// Dismisses a sheet, using the close role when available
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(role: .close, action: action)
        } else {
            Button(.cancel, role: .cancel, action: action)
        }
    }
}

/// Dismisses a sheet like `CloseButton`, first asking whether to discard any changes.
/// Pair it with `interactiveDismissDisabled(hasChanges)` so swiping the sheet away can't skip the question.
struct DiscardCloseButton: View {
    let hasChanges: Bool
    let action: () -> Void

    @State private var showingConfirmation = false

    var body: some View {
        CloseButton {
            if hasChanges {
                showingConfirmation = true
            } else {
                action()
            }
        }
        .confirmationDialog(Text(.discardChangesTitle), isPresented: $showingConfirmation, titleVisibility: .visible) {
            Button(.discardChangesButton, role: .destructive, action: action)
                .accessibilityIdentifier("discard-changes-button")
            Button(.keepEditingButton, role: .cancel) {}
        }
    }
}

/// Confirms a sheet, using the confirm role when available
struct ConfirmButton: View {
    let title: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(role: .confirm, action: action)
        } else {
            Button(title, action: action)
        }
    }
}

extension Color {
    /// The fill behind a grouped-list card
    static let cardBackground = Color(.secondarySystemGroupedBackground)
}

extension View {
    /// Sets the view on a rounded grouped-list card
    func card() -> some View {
        background(Color.cardBackground, in: .rect(cornerRadius: 16))
    }

    /// Asks before deleting the round in `selection`, then calls `onDelete` with it
    func deleteRoundConfirmation(_ selection: Binding<NumberedRound?>,
                                 onDelete: @escaping (NumberedRound) -> Void) -> some View {
        confirmationDialog(
            Text(.deleteRoundConfirmationTitle(selection.wrappedValue?.number ?? 0)),
            isPresented: Binding {
                selection.wrappedValue != nil
            } set: { isPresented in
                if !isPresented {
                    selection.wrappedValue = nil
                }
            },
            titleVisibility: .visible,
            presenting: selection.wrappedValue
        ) { selection in
            Button(.deleteConfirmationButton, role: .destructive) {
                onDelete(selection)
            }
            .accessibilityIdentifier("delete-round-confirmation-button")
            Button(.cancel, role: .cancel) {}
        } message: { _ in
            Text(.deleteRoundConfirmationMessage)
        }
    }

    /// Uses the Liquid Glass prominent style when available
    @ViewBuilder
    func prominentButtonStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }

    /// Lets the Copy command copy `text` when available
    @ViewBuilder
    func copyableText(_ text: @autoclosure @escaping () -> String?) -> some View {
        if #available(iOS 27, *) {
            copyable(text().map { [$0] } ?? [])
        } else {
            self
        }
    }
}
