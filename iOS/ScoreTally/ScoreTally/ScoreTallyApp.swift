//
// ScoreTallyApp
// ScoreTally
//
// Created on 7/5/24
//

import SwiftUI
import SwiftData

@main
struct ScoreTallyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// The store can fail to open, such as when a migration fails, so this keeps the error to show instead of crashing
    private let sharedModelContainer = Result { try ModelContainer.scoreTally() }

    var body: some Scene {
        WindowGroup {
            switch sharedModelContainer {
            case .success(let container):
                GameListView()
                    .modelContainer(container)
            case .failure(let error):
                StoreErrorView(error: error)
            }
        }
    }
}
