//
// RaceChartView
// ScoreTally
//
// Created on 2026-10-09
//

import Charts
import SwiftData
import SwiftUI

/// Each player's running total round by round, so you can see the lead change hands
struct RaceChartView: View {
    let game: Game

    @State private var selectedRound: Int?

    @ScaledMetric(relativeTo: .subheadline) private var rankColumnWidth = 32
    @ScaledMetric(relativeTo: .body) private var avatarSize = 28

    var body: some View {
        // Sorted once here and handed to the chart and leaderboard
        let players = game.players
        let rounds = game.rounds
        let roundCount = rounds.count
        // Every line starts from the player's earlier points, then adds each round
        let totals = players.map { [$0.unrecordedPoints] + game.runningTotals(for: $0, in: rounds) }

        ScrollView {
            VStack(spacing: 16) {
                chart(players: players, totals: totals, roundCount: roundCount)
                    .frame(height: 300)
                    .padding()
                    .card()
                leaderboard(players: players)
                    .card()
            }
            .padding()
        }
    }

    // MARK: Chart

    private func chart(players: [Player], totals: [[Int]], roundCount: Int) -> some View {
        // Plain strings keep these chart labels out of the string catalog
        let roundLabel = String(localized: .rounds)
        let totalLabel = String(localized: .totalRow)

        return Chart {
            ForEach(players.indices, id: \.self) { index in
                let player = players[index]
                let color = player.color.color

                ForEach(totals[index].indices, id: \.self) { round in
                    LineMark(x: .value(roundLabel, round),
                             y: .value(totalLabel, totals[index][round]),
                             series: .value(player.name, index))
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.monotone)
                        .accessibilityLabel(player.name)
                        .accessibilityValue("\(roundName(round)), \(totals[index][round].formatted())")
                }
                PointMark(x: .value(roundLabel, roundCount),
                          y: .value(totalLabel, totals[index][roundCount]))
                    .foregroundStyle(color)
                    .symbolSize(60)
                    .accessibilityHidden(true)
            }

            if let selectedRound {
                let round = min(max(selectedRound, 0), roundCount)
                RuleMark(x: .value(roundLabel, round))
                    .foregroundStyle(.secondary.opacity(0.4))
                    // Stays inside the chart rather than spilling over the toolbar
                    .annotation(position: .top,
                                spacing: 0,
                                overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        callout(for: round, players: players, totals: totals)
                    }
                    .accessibilityHidden(true)
            }
        }
        // Padding at both ends leaves room for the first and last labels, which sit centered on their rounds
        .chartXScale(domain: 0...max(roundCount, 1), range: .plotDimension(startPadding: 20, endPadding: 20))
        // Low-score games flip the axis so the leader is always on top
        .chartYScale(domain: .automatic(includesZero: true, reversed: game.lowScoreWins))
        .chartXAxis {
            AxisMarks(values: axisRounds(through: roundCount)) { value in
                AxisGridLine()
                AxisValueLabel(anchor: .top) {
                    if let round = value.as(Int.self) {
                        Text(round == 0 ? .raceStartLabel : .roundShortLabel(round))
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartXSelection(value: $selectedRound)
        .accessibilityIdentifier("race-chart")
    }

    /// Labels every round in short games and spreads them out in long ones
    private func axisRounds(through roundCount: Int) -> [Int] {
        let step = max(1, Int((Double(roundCount) / 6).rounded(.up)))
        return Array(stride(from: 0, through: roundCount, by: step))
    }

    private func roundName(_ round: Int) -> String {
        round == 0 ? String(localized: .raceStartLabel) : String(localized: .roundA11YLabel(round))
    }

    /// Everyone's total at the selected round, best first
    private func callout(for round: Int, players: [Player], totals: [[Int]]) -> some View {
        let order = players.indices.sorted { first, second in
            let (firstTotal, secondTotal) = (totals[first][round], totals[second][round])
            if firstTotal == secondTotal {
                return first < second
            }
            return game.lowScoreWins ? firstTotal < secondTotal : firstTotal > secondTotal
        }

        return VStack(alignment: .leading, spacing: 4) {
            Text(roundName(round))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            ForEach(order, id: \.self) { index in
                HStack(spacing: 6) {
                    Circle()
                        .fill(players[index].color.color)
                        .frame(width: 8, height: 8)
                    Text(players[index].name)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(totals[index][round].formatted(.number))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }
        }
        .font(.caption)
        .padding(10)
        .frame(maxWidth: 180)
        // A solid fill, since materials render black inside chart annotations
        .background(Color(.systemBackground), in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.separator)
        }
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }

    // MARK: Leaderboard

    private func leaderboard(players: [Player]) -> some View {
        let standings = game.ranking.ordered(players)

        return VStack(spacing: 0) {
            ForEach(Array(standings.enumerated()), id: \.element.player.id) { offset, entry in
                if offset > 0 {
                    // Lines up with the avatars: row padding, rank column, then row spacing
                    Divider()
                        .padding(.leading, 16 + rankColumnWidth + 12)
                }
                leaderboardRow(for: entry.player, rank: entry.rank)
            }
        }
    }

    private func leaderboardRow(for player: Player, rank: Int?) -> some View {
        let isLeader = rank == 0

        return HStack(spacing: 12) {
            Group {
                if let rank {
                    Text((rank + 1).ordinalFormatted)
                } else {
                    Dash()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(width: rankColumnWidth, alignment: .leading)
            PlayerAvatar(player: player, size: avatarSize)
            Text(player.name)
                .fontWeight(isLeader ? .semibold : .regular)
                .lineLimit(1)
            if isLeader {
                CrownBadge()
            }
            Spacer(minLength: 8)
            Text(player.total.formatted(.number))
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(.leader(isLeader, color: player.color.color))
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(player.name)
        .accessibilityValue(
            rank.map { String(localized: .playerTotalA11YValue(player.name, player.total, $0 + 1)) }
                ?? String(localized: .playerRoundPointsA11YValue(player.name, player.total))
        )
    }
}

#if DEBUG
#Preview(traits: .sampleData) {
    @Previewable @Query var games: [Game] = [Game]()
    RaceChartView(game: games.first { !$0.rounds.isEmpty }!)
        .background(Color(.systemGroupedBackground))
}
#endif
