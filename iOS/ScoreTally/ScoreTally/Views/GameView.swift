//
// File
// ScoreTally
//
// Created on 7/5/24
//

import SwiftData
import SwiftUI

enum PlayerSortOrder: String, CaseIterable {
    case pointsForward
    case pointsReverse
    case forward
    case reverse

    var title: LocalizedStringResource {
        switch self {
        case .forward:
            .sortAscendingRightClickAction
        case .reverse:
            .sortDescendingRightClickAction
        case .pointsForward:
            .sortScoreAscendingRightClickAction
        case .pointsReverse:
            .sortScoreDescendingRightClickAction
        }
    }

    var sortPredicate: any SortComparator<Player> {
        switch self {
        case .forward:
            return SortDescriptor(\Player.creationDate, order: .forward)
        case .reverse:
            return SortDescriptor(\Player.creationDate, order: .reverse)
        case .pointsForward:
            return KeyPathComparator(\Player.total, order: .forward)
        case .pointsReverse:
            return KeyPathComparator(\Player.total, order: .reverse)
        }
    }
}

struct GameView: View {
    let game: Game

    @State private var showingScorePopover = false
    @State private var showingRounds = false

    @State private var showingAddPlayer = false

    @State private var showingEditPopover = false

    /// GameListView applies this, since it knows when any game is showing
    @AppStorage("keep-screen-on") private var keepScreenOn = true

    @AppStorage("playerSortOrder") private var sortOrder: PlayerSortOrder = .forward
    private var sortedPlayers: [Player] {
        game.players.sorted(using: sortOrder.sortPredicate)
    }

    /// The rounds table only has something to show once a round has been scored
    private var hasRounds: Bool {
        game.hasRounds
    }

    /// The Duo splits the game so the scores sit on the top half and the controls on the bottom half when folded
    private var usesFoldArrangement: Bool {
        guard #available(iOS 27.1, *) else {
            return false
        }
        return UIDevice.current.isDuo
    }

    init(with game: Game) {
        self.game = game
    }

    var body: some View {
        Group {
            if #available(iOS 27.1, *), usesFoldArrangement {
                // Keeps the scores on the top half and the controls on the bottom half when folded
                ArrangementView {
                    ScrollView {
                        playerGrid
                    }
                } secondary: {
                    foldPrimaryAction
                        .splitArrangementFixedLayoutSize()
                }
                .arrangementViewStyle(.split)
            } else {
                ScrollView {
                    playerGrid
                }
                .overlay {
                    if !game.hasPlayers {
                        ContentUnavailableView {
                            Label(.noPlayersTitle, systemImage: "person.2")
                        } description: {
                            Text(.noPlayersDescription)
                        } actions: {
                            Button(.addPlayer, action: showAddPlayer)
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
        .navigationTitle(game.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .copyableText(game.description)
        .sheet(isPresented: $showingScorePopover) {
            // In the grid's order, so everyone is where they were just seen
            ScoreRoundPopover(for: game, players: sortedPlayers)
                .presentationSizing(.form)
        }
        .sheet(isPresented: $showingRounds) {
            RoundTableView(for: game)
                .presentationSizing(.page)
        }
        .sheet(isPresented: $showingAddPlayer) {
            PlayerEditView(adding: game)
                .presentationSizing(.form)
        }
        .sheet(isPresented: $showingEditPopover) {
            GameEditPopover(for: game)
                .presentationSizing(.form)
        }
        .toolbar {
            ToolbarItem {
                Button(action: showAddPlayer) {
                    Label(.addPlayer, systemImage: "plus")
                }
                .accessibilityInputLabels([Text(.addPlayer), Text(.inputLabelAdd), Text(.inputLabelNew)])
                .accessibilityIdentifier("add-player")
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            // Less frequent settings share a menu so the title has room
            ToolbarItem {
                Menu {
                    Picker(selection: $sortOrder) {
                        ForEach(PlayerSortOrder.allCases, id: \.self) { order in
                            Text(order.title)
                        }
                    } label: {
                        Label(.switchSortOrder, systemImage: "arrow.up.arrow.down")
                    }
                    .pickerStyle(.menu)

                    Toggle(isOn: $keepScreenOn) {
                        Label(.keepScreenOn, systemImage: "sun.max")
                    }
                    .accessibilityIdentifier("keep-screen-on")

                    Button(action: showEditGame) {
                        Label(.editGameRightClickAction, systemImage: "pencil")
                    }
                } label: {
                    Label(.gameOptions, systemImage: "ellipsis")
                }
                .accessibilityInputLabels([Text(.gameOptions), Text(.inputLabelOptions), Text(.inputLabelMore)])
                .accessibilityIdentifier("game-options")
            }

            if game.hasPlayers && !usesFoldArrangement {
                if #available(iOS 26, *) {
                    if hasRounds {
                        ToolbarItem(placement: .bottomBar) {
                            roundsButton
                        }
                    }
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                    // Keeps the bar's shared glass behind it: hiding that leaves the prominent label
                    // drawn in white on the page, so the button disappears
                    ToolbarItem(placement: .bottomBar) {
                        scoreRoundButton
                    }
                } else {
                    ToolbarItemGroup(placement: .bottomBar) {
                        if hasRounds {
                            roundsButton
                        }
                        Spacer()
                        scoreRoundButton
                    }
                }
            } else if game.hasPlayers && hasRounds {
                ToolbarItem {
                    roundsButton
                }
            }
        }
        #if os(iOS)
        .toolbarRole(.navigationStack)
        #endif
        .toolbarVisibility(.visible, for: .automatic)
    }

    private var playerGrid: some View {
        // Placed once here rather than by each card
        let standings = game.standings
        let winningScore = standings.winningScore
        return LazyVGrid(
            columns: [GridItem(spacing: 12), GridItem(spacing: 12)],
            spacing: 12
        ) {
            ForEach(Array(zip(sortedPlayers.indices, sortedPlayers)), id: \.1.id) { (index, player) in
                GameViewPlayerCellView(
                    for: player,
                    place: standings.place(of: player.total),
                    leadsAlone: player.total == winningScore
                )
                    .accessibilityIdentifier("player-\(index)")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    /// The large action shown below the fold on the Duo
    private var foldPrimaryAction: some View {
        Group {
            if !game.hasPlayers {
                Button(action: showAddPlayer) {
                    Label(.addPlayer, systemImage: "plus")
                        .font(.title.bold())
                        .padding()
                }
            } else {
                Button(action: scoreRound) {
                    Text(.scoreRound)
                        .font(.title.bold())
                        .padding()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .accessibilityIdentifier("score-round")
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .tint(.accentColor)
    }

    private var roundsButton: some View {
        Button(action: showRounds) {
            Label(.rounds, systemImage: "tablecells")
        }
        .accessibilityIdentifier("show-rounds")
        .keyboardShortcut("r", modifiers: [.command, .shift])
    }

    private var scoreRoundButton: some View {
        Button(action: scoreRound) {
            Label(.scoreRound, systemImage: "plus.circle.fill")
                .labelStyle(.titleAndIcon)
                .font(.headline)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .prominentButtonStyle()
        .controlSize(.large)
        .keyboardShortcut("s", modifiers: [.command, .shift])
        .accessibilityInputLabels([Text(.scoreRound), Text(.inputLabelScore)])
        .accessibilityIdentifier("score-round")
    }

    private func scoreRound() {
        showingScorePopover = true
    }

    private func showRounds() {
        showingRounds = true
    }

    private func showAddPlayer() {
        showingAddPlayer = true
    }

    private func showEditGame() {
        showingEditPopover = true
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

#Preview("Scored Game", traits: .sampleData) {
    @Previewable @Query(filter: #Predicate<Game> { $0.name == "Family Game Night" }) var games: [Game]
    PushedGamePreview(game: games.first!)
}

#Preview("Long Name and Ties", traits: .sampleData) {
    @Previewable @Query(filter: #Predicate<Game> { $0.name.starts(with: "Saturday") }) var games: [Game]
    PushedGamePreview(game: games.first!)
}

/// Pushes the game so the toolbar has a back button, as it does on iPhone
private struct PushedGamePreview: View {
    let game: Game

    var body: some View {
        NavigationStack {
            Color.clear
                .navigationDestination(isPresented: .constant(true)) {
                    GameView(with: game)
                }
        }
    }
}
#endif
