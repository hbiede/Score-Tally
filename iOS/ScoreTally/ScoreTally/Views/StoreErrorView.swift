//
// StoreErrorView
// ScoreTally
//
// Created on 2026-10-16
//

import SwiftUI

/// Shown in place of the game list when the saved games can't be opened, such as after a failed migration.
/// The store is left alone so a fixed version of the app can still open it.
struct StoreErrorView: View {
    let error: any Error

    var body: some View {
        ContentUnavailableView {
            Label(.storeErrorTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(.storeErrorDescription)
        } actions: {
            Text(String(describing: error))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    StoreErrorView(error: CocoaError(.fileReadCorruptFile))
}
