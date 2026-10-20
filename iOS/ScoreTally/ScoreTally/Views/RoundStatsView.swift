//
// RoundStatsView
// ScoreTally
//
// Created on 2026-10-16
//

import SwiftData
import SwiftUI

/// Records and per-player figures from a game's rounds: who's hot, who's steady, and how the lead has moved
struct RoundStatsView: View {
    let game: Game

    @ScaledMetric(relativeTo: .title2) private var tileWidth = 150
    @ScaledMetric(relativeTo: .body) private var iconSize = 32

    var body: some View {
        // Sorted once here and handed to every section
        let players = game.players
        let stats = GameStats(game: game)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                tiles(for: stats)
                highlights(for: stats, players: players)
                playerSection(for: stats, players: players)
            }
            .padding()
        }
        .accessibilityIdentifier("round-stats")
    }

    // MARK: Tiles

    @ViewBuilder
    private func tiles(for stats: GameStats<PersistentIdentifier>) -> some View {
        let gridSpacing: CGFloat = 12

        LazyVGrid(columns: [GridItem(.adaptive(minimum: tileWidth), spacing: gridSpacing)], spacing: gridSpacing) {
            tile(.rounds, systemImage: "number") {
                Text(stats.completeRounds.formatted(.number))
            }
            tile(.leadChangesStat, systemImage: "arrow.left.arrow.right") {
                Text(stats.leadChanges.formatted(.number))
            }
            tile(.leadMarginStat, systemImage: "ruler") {
                switch stats.leadMargin {
                case 0?:
                    Text(.tiedStatValue)
                case let margin?:
                    Text(margin.formatted(.number))
                case nil:
                    Dash()
                }
            }
            tile(.averagePointsStat, systemImage: "divide") {
                if let average = stats.averagePoints {
                    Text(average.averageFormatted)
                } else {
                    Dash()
                }
            }
        }
    }

    private func tile<Value: View>(_ title: LocalizedStringResource,
                                   systemImage: String,
                                   @ViewBuilder value: () -> Value) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            value()
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .card()
        .accessibilityElement(children: .combine)
    }

    // MARK: Highlights

    private func highlightList(for stats: GameStats<PersistentIdentifier>, players: [Player]) -> [StatHighlight] {
        let players = Dictionary(players.map { ($0.persistentModelID, $0) }) { first, _ in first }
        func highlight(_ kind: StatHighlightKind,
                       for player: PersistentIdentifier,
                       value: StatHighlight.Value,
                       detail: LocalizedStringResource?) -> StatHighlight? {
            players[player].map { StatHighlight(kind: kind, player: $0, value: value, detail: detail) }
        }

        return [
            stats.bestRound.flatMap {
                highlight(.bestRound, for: $0.player, value: .points($0.value), detail: .roundA11YLabel($0.round))
            },
            stats.hotStreak.flatMap {
                highlight(.hotStreak, for: $0.player, value: .points($0.value), detail: .consecutiveStatDetail)
            },
            stats.biggestLead.flatMap {
                highlight(.biggestLead, for: $0.player, value: .points($0.value), detail: .roundA11YLabel($0.round))
            },
            stats.biggestClimb.flatMap {
                highlight(.biggestClimb, for: $0.player, value: .climb($0.fromRank, $0.toRank), detail: nil)
            },
            stats.mostConsistent.flatMap {
                highlight(.mostConsistent, for: $0.player, value: .deviation($0.deviation), detail: .perRoundStatDetail)
            }
        ]
        .compactMap { $0 }
    }

    @ViewBuilder
    private func highlights(for stats: GameStats<PersistentIdentifier>, players: [Player]) -> some View {
        let highlights = highlightList(for: stats, players: players)

        if !highlights.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader(.highlightsSectionTitle)

                VStack(spacing: 0) {
                    ForEach(Array(highlights.enumerated()), id: \.element.id) { offset, highlight in
                        if offset > 0 {
                            // Lines up with the text: row padding, icon, then row spacing
                            Divider()
                                .padding(.leading, 16 + iconSize + 12)
                        }
                        StatHighlightRow(highlight: highlight, iconSize: iconSize)
                    }
                }
                .card()
            }
        }
    }

    // MARK: Players

    private func playerSection(for stats: GameStats<PersistentIdentifier>, players: [Player]) -> some View {
        let standings = game.ranking.ordered(players)
        // Every sparkline shares a scale from zero, so bars compare across players
        let domain = stats.pointRange.map { range in
            min(range.lowerBound, 0)...max(range.upperBound, range.lowerBound + 1, 1)
        }

        return VStack(alignment: .leading, spacing: 8) {
            sectionHeader(.playersSectionTitle)
            VStack(spacing: 0) {
                ForEach(Array(standings.enumerated()), id: \.element.player.persistentModelID) { offset, entry in
                    if offset > 0 {
                        Divider()
                            .padding(.leading)
                    }
                    if let playerStats = stats.players[entry.player.persistentModelID] {
                        StatsPlayerRow(player: entry.player,
                                       stats: playerStats,
                                       isLeader: entry.rank == 0,
                                       domain: domain)
                    }
                }
            }
            .card()
        }
    }

    private func sectionHeader(_ title: LocalizedStringResource) -> some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal, 4)
            .accessibilityAddTraits(.isHeader)
    }
}

#if DEBUG
#Preview(traits: .sampleData) {
    @Previewable @Query var games: [Game] = [Game]()
    RoundStatsView(game: games.first { !$0.rounds.isEmpty }!)
        .background(Color(.systemGroupedBackground))
}
#endif
