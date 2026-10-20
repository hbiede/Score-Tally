//
// RoundTableView
// ScoreTally
//
// Created on 2026-10-09
//

import SwiftData
import SwiftUI

/// A score sheet breaking each player's points down by round
struct RoundTableView: View {
    @Environment(\.dismiss) private var dismiss

    private let game: Game

    @AppStorage("roundViewMode") private var mode: RoundViewMode = .table

    @ScaledMetric(relativeTo: .body) private var labelColumnWidth = 64
    @ScaledMetric(relativeTo: .body) private var minimumColumnWidth = 72
    @ScaledMetric(relativeTo: .body) private var maximumColumnWidth = 160
    @State private var availableWidth: CGFloat = 0
    /// The natural width of the longest player name, measured from the header
    @State private var widestName: CGFloat = 0

    @State private var scrollPosition = ScrollPosition()

    @State private var editingRound: NumberedRound?
    @State private var roundPendingDeletion: NumberedRound?

    /// Space between the card and the screen edges
    private let cardInset: CGFloat = 16

    /// Fits the longest name (within limits) and spreads out to fill the screen.
    /// When that's wider than the screen the table scrolls sideways instead of squeezing.
    private func columnWidth(for playerCount: Int) -> CGFloat {
        let fitted = min(max(minimumColumnWidth, widestName + 16), maximumColumnWidth)
        guard playerCount > 0 else {
            return fitted
        }
        return max(fitted, (availableWidth - cardInset * 2 - labelColumnWidth) / CGFloat(playerCount))
    }

    init(for game: Game) {
        self.game = game
    }

    var body: some View {
        // Sorted once here and handed to every row, rather than re-sorted for each cell
        let players = game.players
        let rounds = game.rounds
        let hasUnrecordedPoints = players.contains { $0.unrecordedPoints != 0 }
        let hasHistory = !rounds.isEmpty || hasUnrecordedPoints

        NavigationStack {
            Group {
                if !hasHistory {
                    ContentUnavailableView {
                        Label(.noRoundsTitle, systemImage: "tablecells")
                    } description: {
                        Text(.noRoundsDescription)
                    }
                } else if mode == .race {
                    RaceChartView(game: game)
                } else if mode == .stats {
                    RoundStatsView(game: game)
                } else {
                    table(players: players, rounds: rounds, hasUnrecordedPoints: hasUnrecordedPoints)
                }
            }
            .background(Color(.systemGroupedBackground))
            .sheet(item: $editingRound) { selection in
                RoundEditView(round: selection.round, number: selection.number, in: game)
                    .presentationSizing(.form)
            }
            .deleteRoundConfirmation($roundPendingDeletion) { selection in
                withAnimation {
                    game.deleteRound(selection.round)
                }
            }
            .navigationTitle(.rounds)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton(action: { dismiss() })
                        .keyboardShortcut(.cancelAction)
                        .accessibilityIdentifier("close")
                }
                if hasHistory {
                    // Takes the title's place; the title still names the sheet for VoiceOver
                    ToolbarItem(placement: .principal) {
                        Picker(selection: $mode) {
                            ForEach(RoundViewMode.allCases, id: \.self) { mode in
                                Text(mode.title)
                            }
                        } label: {
                            Text(.rounds)
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                        .accessibilityIdentifier("round-view-mode")
                    }
                }
            }
        }
    }

    private func table(players: [Player], rounds: [Round], hasUnrecordedPoints: Bool) -> some View {
        let ranking = game.ranking
        let runningTotals = players.map { game.runningTotals(for: $0, in: rounds) }
        let columnWidth = columnWidth(for: players.count)

        // The horizontal scroll view sits outside so the pinned rows scroll sideways with their columns
        return ScrollView(.horizontal) {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders, .sectionFooters]) {
                    Section {
                        if hasUnrecordedPoints {
                            earlierRow(players: players, columnWidth: columnWidth)
                        }
                        ForEach(Array(rounds.enumerated()), id: \.element.id) { index, round in
                            roundRow(for: round,
                                     number: index + 1,
                                     runningTotals: runningTotals.map { $0[index] },
                                     players: players,
                                     columnWidth: columnWidth,
                                     followsEarlierRow: hasUnrecordedPoints)
                        }
                    } header: {
                        headerRow(players: players, ranking: ranking, columnWidth: columnWidth)
                    } footer: {
                        totalRow(players: players, ranking: ranking, columnWidth: columnWidth)
                    }
                }
                .background(Color.cardBackground)
                .clipShape(.rect(cornerRadius: 16))
                .padding(cardInset)
            }
            .scrollPosition($scrollPosition)
            // Opens on the latest rounds. Positioning the lazy stack before its first layout, as
            // defaultScrollAnchor does, throws its pinned rows off screen and leaves the table blank.
            .task {
                scrollPosition.scrollTo(edge: .bottom)
            }
            .frame(width: labelColumnWidth + columnWidth * CGFloat(players.count) + cardInset * 2)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            availableWidth = width
        }
    }
}

// MARK: Rows

extension RoundTableView {
    private func headerRow(players: [Player], ranking: Ranking, columnWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            tableRow(players: players, columnWidth: columnWidth) {
                Color.clear
                    .frame(height: 0)
            } cell: { index in
                PlayerHeaderCell(player: players[index], isLeader: ranking.rank(of: players[index]) == 0) { width in
                    widestName = max(widestName, width)
                }
            }
            Divider()
        }
        .background(Color.cardBackground)
        .accessibilityAddTraits(.isHeader)
    }

    /// Each player's total, how close they are to the lead, and their place
    private func totalRow(players: [Player], ranking: Ranking, columnWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            Divider()
            tableRow(players: players, columnWidth: columnWidth) {
                Text(.totalRow)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            } cell: { index in
                let player = players[index]
                TotalCell(player: player,
                          rank: ranking.rank(of: player),
                          lead: ranking.lead(of: player),
                          barWidth: columnWidth - 28)
            }
        }
        .background(Color.cardBackground)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.totalRow))
        .accessibilityValue(
            players.map { player in
                if let rank = ranking.rank(of: player) {
                    String(localized: .playerTotalA11YValue(player.name, player.total, rank + 1))
                } else {
                    String(localized: .playerRoundPointsA11YValue(player.name, player.total))
                }
            }
            .formatted(.list(type: .and, width: .narrow))
        )
        .accessibilityIdentifier("round-total")
    }

    /// Points from before rounds were recorded
    private func earlierRow(players: [Player], columnWidth: CGFloat) -> some View {
        let points = players.map { Optional($0.unrecordedPoints) }

        return tableRow(players: players, columnWidth: columnWidth) {
            Text(.earlierRow)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } cell: { index in
            if let value = points[index] {
                Text(value.formatted(.number))
                    .foregroundStyle(value.pointsStyle)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.earlierRow))
        .accessibilityValue(accessibilityValue(for: points, players: players))
        .accessibilityIdentifier("round-earlier")
    }

    private func roundRow(for round: Round,
                          number: Int,
                          runningTotals: [Int],
                          players: [Player],
                          columnWidth: CGFloat,
                          followsEarlierRow: Bool) -> some View {
        let points = players.map { round.points(for: $0) }
        let standings = Standings(scores: points.compactMap { $0 }, lowScoreWins: game.lowScoreWins)
        let isBest = points.map { $0.map { standings.place(of: $0) == 0 } ?? false }
        let selection = NumberedRound(round: round, number: number)

        return Button {
            editingRound = selection
        } label: {
            tableRow(players: players, columnWidth: columnWidth) {
                roundLabel(for: round, number: number)
            } cell: { index in
                RoundCell(points: points[index],
                          runningTotal: runningTotals[index],
                          isBest: isBest[index],
                          color: players[index].color.color)
            }
            .contentShape(.rect)
        }
        .buttonStyle(RowButtonStyle())
        .contextMenu {
            roundActions(for: selection)
        }
        .overlay(alignment: .top) {
            // The header's divider already sits above the first row
            if number > 1 || followsEarlierRow {
                roundDivider(isComplete: round.isComplete)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.roundA11YLabel(number)))
        .accessibilityValue(accessibilityValue(for: points,
                                               players: players,
                                               isBest: isBest,
                                               inProgress: !round.isComplete))
        // Ignoring the children drops the button's own action, so it's added back
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            editingRound = selection
        }
        .accessibilityAction(named: Text(.deleteRound)) {
            roundPendingDeletion = selection
        }
        .accessibilityIdentifier("round-\(number)")
    }

    // MARK: Building blocks

    /// The round's short name, marked while it's still collecting points
    private func roundLabel(for round: Round, number: Int) -> some View {
        HStack(spacing: 4) {
            if !round.isComplete {
                Circle()
                    .fill(.tint)
                    .frame(width: 6, height: 6)
            }
            Text(.roundShortLabel(number))
        }
        .font(.subheadline)
        .foregroundStyle(round.isComplete ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
    }

    /// Edits or deletes a round from its context menu
    @ViewBuilder
    private func roundActions(for selection: NumberedRound) -> some View {
        Button {
            editingRound = selection
        } label: {
            Label(.editRoundRightClickAction, systemImage: "pencil")
        }
        .accessibilityIdentifier("edit-round-right-click-action")
        Button(role: .destructive) {
            roundPendingDeletion = selection
        } label: {
            Label(.deleteRound, systemImage: "trash")
        }
        .accessibilityIdentifier("delete-round-right-click-action")
    }

    /// A line above a round, dashed while it's still collecting points
    @ViewBuilder
    private func roundDivider(isComplete: Bool) -> some View {
        if isComplete {
            Divider()
        } else {
            TopEdge()
                .stroke(.separator, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .frame(height: 1)
        }
    }

    /// Lays out a label followed by one fixed-width cell per player so every row lines up
    private func tableRow<RowLabel: View, Cell: View>(
        players: [Player],
        columnWidth: CGFloat,
        @ViewBuilder label: () -> RowLabel,
        @ViewBuilder cell: @escaping (Int) -> Cell
    ) -> some View {
        HStack(spacing: 0) {
            label()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.leading)
                .frame(width: labelColumnWidth, alignment: .leading)
            ForEach(players.indices, id: \.self) { index in
                cell(index)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: columnWidth)
            }
        }
        .padding(.vertical, 10)
    }

    private func accessibilityValue(for points: [Int?],
                                    players: [Player],
                                    isBest: [Bool]? = nil,
                                    inProgress: Bool = false) -> String {
        let entries = players.indices.map { index in
            let name = players[index].name
            guard let value = points[index] else {
                return String(localized: .playerRoundNotPlayedA11YValue(name))
            }
            if isBest?[index] == true {
                return String(localized: .playerRoundBestA11YValue(name, value))
            }
            return String(localized: .playerRoundPointsA11YValue(name, value))
        }
        let status = inProgress ? [String(localized: .roundInProgressA11YValue)] : []
        return (status + entries).formatted(.list(type: .and, width: .narrow))
    }
}

#if DEBUG
import SwiftData

#Preview(traits: .sampleData) {
    @Previewable @Query var games: [Game] = [Game]()
    RoundTableView(for: games.first { !$0.rounds.isEmpty }!)
}
#endif
