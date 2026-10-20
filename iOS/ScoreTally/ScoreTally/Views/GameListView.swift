//
// ContentView
// ScoreTally
//
// Created on 7/5/24
//

import SwiftUI
import SwiftData

struct GameListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager

    @Query(sort: [SortDescriptor(\Game.createdDate, order: .reverse),
                  SortDescriptor(\Game.name, order: .forward)])
    private var games: [Game]

    @State private var selection: PersistentIdentifier?
    @SceneStorage("selectedGame") private var storedSelection: Data?

    @State private var showingNewGame = false

    @AppStorage("keep-screen-on") private var keepScreenOn = true

    @State private var searchText = ""
    private var searchResults: [Game] {
        if !searchText.isEmpty, let filteredGames = try? games.filter(#Predicate {
            $0.name.localizedStandardContains(searchText)
        }) {
            filteredGames
        } else {
            games
        }
    }

    private var selectedGame: Game? {
        games.first { $0.persistentModelID == selection }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(Array(zip(searchResults.indices, searchResults)), id: \.1.id) { (index, game) in
                    NavigationLink(value: game.persistentModelID) {
                        GameListViewCell(game: game, onSelect: select)
                    }
                    .accessibilityIdentifier("game-\(index)")
                }
            }
            .overlay {
                if games.isEmpty {
                    ContentUnavailableView {
                        Label(.noGamesTitle, systemImage: "list.number")
                    } description: {
                        Text(.noGamesDescription)
                    } actions: {
                        Button(.createGameTitle, action: displayPrompt)
                            .buttonStyle(.borderedProminent)
                    }
                } else if searchResults.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem {
                    Button(action: displayPrompt) {
                        Label(.addGame, systemImage: "plus")
                    }
                    .accessibilityInputLabels([Text(.addGame), Text(.inputLabelAdd), Text(.inputLabelNew)])
                    .accessibilityIdentifier("add-game")
                    .keyboardShortcut("n", modifiers: .command)
                }
                if #available(iOS 26, *) {
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                }
            }
            .sheet(isPresented: $showingNewGame) {
                NewGameView(onCreate: select)
                    .presentationSizing(.form)
            }
            .navigationTitle(.appTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .copyableText(selectedGame?.description)
        } detail: {
            if let selectedGame {
                GameView(with: selectedGame)
                    .id(selectedGame.persistentModelID)
            } else {
                ContentUnavailableView {
                    Label(.noGameSelectedTitle, systemImage: "list.number")
                } description: {
                    Text(.noGameSelectedDescription)
                }
            }
        }
        .onAppear(perform: restoreSelection)
        .onChange(of: selection) {
            storedSelection = selection.flatMap { try? JSONEncoder().encode($0) }
        }
        .onChange(of: games) {
            if selectedGame == nil {
                selection = nil
            }
        }
        .onChange(of: undoManager, initial: true) {
            modelContext.undoManager = undoManager
        }
        // Set here rather than as each GameView appears and disappears, since switching games
        // can show the new one before the old one disappears and turns the idle timer back on
        .onChange(of: selectedGame != nil && keepScreenOn, initial: true) { _, keepAwake in
            UIApplication.shared.isIdleTimerDisabled = keepAwake
        }
    }

    private func displayPrompt() {
        showingNewGame = true
    }

    /// Opens `game`, such as one that was just created or duplicated
    private func select(_ game: Game) {
        selection = game.persistentModelID
    }

    private func restoreSelection() {
        guard selection == nil,
              let storedSelection,
              let storedID = try? JSONDecoder().decode(PersistentIdentifier.self, from: storedSelection),
              games.contains(where: { $0.persistentModelID == storedID }) else {
            return
        }
        selection = storedID
    }
}

#if DEBUG
#Preview(traits: .sampleData) {
    GameListView()
        .environment(\.locale, Locale(identifier: "en"))
}
#endif
