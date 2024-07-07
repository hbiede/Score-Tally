//
// File
// ScoreTally 
//
// Created on 7/5/24
//

import SwiftUI

enum PlayerSortOrder {
    case forward
    case reverse
    case pointsForward
    case pointsReverse

    var isAscending: Bool {
        self == .forward || self == .pointsForward
    }

    var sortPredicate: any SortComparator<Player> {
        switch self {
        case .forward:
            return SortDescriptor(\Player.creationDate, order: .forward)
        case .reverse:
            return SortDescriptor(\Player.creationDate, order: .reverse)
        case .pointsForward:
            return SortDescriptor(\Player.score, order: .forward)
        case .pointsReverse:
            return SortDescriptor(\Player.score, order: .reverse)
        }
    }
}

struct GameView: View {
    @Environment(\.modelContext) private var modelContext

    let game: Game

    @State private var showingScorePopover = false

    @State private var displayCreationPrompt = false
    @State private var createPlayerName = ""

    @State private var sortOrder: PlayerSortOrder = .forward
    private var sortedPlayers: [Player] {
        game.players.sorted(using: sortOrder.sortPredicate)
    }

    init(with game: Game) {
        self.game = game
    }

    var body: some View {
        ScrollView {
            if game.players.isEmpty {
                Button(action: showAddPlayer) {
                    Label("add-player", systemImage: "plus")
                        .font(.title.bold())
                        .padding(.all)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.all)
                .tint(.accentColor)
            } else {
                Button(action: scoreRound) {
                    Text("score-round")
                        .font(.title.bold())
                        .padding(.all)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .accessibilityIdentifier("score-round")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.all)
                .tint(.accentColor)
            }

            LazyVGrid(
                columns: [GridItem(spacing: 8), GridItem(spacing: 8)],
                spacing: 8
            ) {
                ForEach(Array(zip(sortedPlayers.indices, sortedPlayers)), id: \.1.id) { (index, player) in
                    GameViewPlayerCellView(for: player)
                        .accessibilityIdentifier("player-\(index)")
                        .frame(maxWidth: .infinity)
                }
                .onDelete(perform: deletePlayers)
            }
            .padding(.horizontal)
        }
        .navigationTitle(game.name)
        .fullScreenCover(isPresented: $showingScorePopover, onDismiss: {
            showingScorePopover = false
        }) {
            ScoreRoundPopover(for: game.players)
                .presentationCompactAdaptation(.fullScreenCover)
        }
        .toolbar {
            Button(action: showAddPlayer) {
                Label("add-player", systemImage: "plus")
            }
            .accessibilityIdentifier("add-player")
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .alert("create-player-title", isPresented: $displayCreationPrompt) {
                TextField("create-player-placeholder", text: $createPlayerName)

                Button("cancel", role: .cancel) {
                    cancelCreation()
                }
                .accessibilityIdentifier("cancel")
                Button("create-player-button-title") {
                    addPlayer(with: createPlayerName)
                }
                .accessibilityIdentifier("create-player-button-title")
                .disabled(createPlayerName.isEmpty)
            }
            Button(action: switchSortOrder) {
                Label(title: {
                    Text("switch-sort-order")
                }, icon: {
                    Image(systemName: "arrow.up.arrow.down")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(sortOrder.isAscending
                                         ? Color.accent
                                         : Color.accent.opacity(0.8),
                                         sortOrder.isAscending
                                         ? Color.accent.opacity(0.8)
                                         : Color.accent)
                })
            }
            .contextMenu {
                Button("sort-ascending-right-click-action") {
                    sortOrder = .forward
                }
                Button("sort-descending-right-click-action") {
                    sortOrder = .reverse
                }
                Button("sort-score-ascending-right-click-action") {
                    sortOrder = .pointsForward
                }
                Button("sort-score-descending-right-click-action") {
                    sortOrder = .pointsReverse
                }
            }
        }
        #if os(iOS)
        .toolbarRole(.navigationStack)
        #endif
        .toolbarVisibility(.visible, for: .automatic)
    }

    private func addPlayer(with name: String) {
        game.addPlayer(with: createPlayerName)
    }

    private func cancelCreation() {
        displayCreationPrompt = false
    }

    private func deletePlayers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(game.players[index])
            }
        }
    }

    private func scoreRound() {
        showingScorePopover = true
    }

    private func showAddPlayer() {
        createPlayerName = ""
        displayCreationPrompt = true
    }

    func switchSortOrder() {
        sortOrder = {
            switch sortOrder {
            case .forward:
                    .reverse
            case .reverse:
                    .pointsForward
            case .pointsForward:
                    .pointsReverse
            case .pointsReverse:
                    .forward
            }
        }()
    }
}

#if DEBUG
import SwiftData

#Preview(traits: .sampleData) {
    @Previewable @Query var games: [Game] = [Game]()
    NavigationStack {
        GameView(with: games.first!)
    }
}
#endif
