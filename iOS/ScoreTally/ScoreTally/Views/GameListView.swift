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
    
    @Query(sort: [SortDescriptor(\Game.createdDate, order: .reverse),
                  SortDescriptor(\Game.name, order: .forward)])
    private var games: [Game]

    @State private var selectedGame: Int? = nil
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    @State private var displayCreationPrompt = false
    @State private var createGameTitle = ""

    @State private var searchText = ""
    private var searchResults: [Game] {
        if !searchText.isEmpty, let filteredGames = try? games.filter(#Predicate { $0.name.localizedStandardContains(searchText) }) {
            filteredGames
        } else {
            games
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(zip(searchResults.indices, searchResults)), id: \.1.id) { (index, game) in
                    NavigationLink {
                        GameView(with: game)
                    } label: {
                        GameListViewCell(game: game)
                    }
                    .accessibilityIdentifier("game-\(index)")
                }
                .onDelete(perform: deleteGames)
            }
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem {
                    Button(action: displayPrompt) {
                        Label("add-game", systemImage: "plus")
                    }
                    .accessibilityIdentifier("add-game")
                    .keyboardShortcut("n", modifiers: .command)
                    .alert("create-game-title", isPresented: $displayCreationPrompt) {
                        TextField("create-game-placeholder", text: $createGameTitle)

                        Button("cancel", role: .cancel) {
                            cancelCreation()
                        }
                        .accessibilityIdentifier("cancel")
                        Button("create-game-button-title") {
                            addGame(with: createGameTitle)
                        }
                        .accessibilityIdentifier("create-game-button-title")
                        .disabled(createGameTitle.isEmpty)
                    }
                }
            }
            .navigationTitle("app-title")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                #if targetEnvironment(simulator)
                selectedGame = games.firstIndex(where: { $0.selected })
                #else
                if games.isEmpty {
                    displayPrompt()
                } else {
                    selectedGame = games.firstIndex(where: { $0.selected })
                }
                #endif
            }
            .onChange(of: searchText) {
                selectedGame = nil
            }
            .onChange(of: selectedGame) {
                if let selectedGame = selectedGame {
                    games.forEach { $0.selected = false }
                    games[selectedGame].selected = true
                }
            }
        }
    }

    private func displayPrompt() {
        createGameTitle = ""
        displayCreationPrompt = true
    }

    private func cancelCreation() {
        displayCreationPrompt = false
    }

    private func addGame(with title: String) {
        displayCreationPrompt = false
        withAnimation {
            modelContext.insert(Game(name: title))
        }
    }

    private func deleteGames(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(games[index])
            }
        }
    }
}

#if DEBUG
#Preview(traits: .sampleData) {
    GameListView()
        .environment(\.locale, Locale(identifier: "en"))
}
#endif
