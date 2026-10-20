//
// RoundStatsCells
// ScoreTally
//
// Created on 2026-10-16
//

import Charts
import SwiftData
import SwiftUI

/// The records worth calling out on the stats tab
enum StatHighlightKind: String {
    case bestRound = "best-round"
    case hotStreak = "hot-streak"
    case biggestLead = "biggest-lead"
    case biggestClimb = "biggest-climb"
    case mostConsistent = "most-consistent"

    var title: LocalizedStringResource {
        switch self {
        case .bestRound:
            .bestRoundStat
        case .hotStreak:
            .hotStreakStat
        case .biggestLead:
            .biggestLeadStat
        case .biggestClimb:
            .biggestClimbStat
        case .mostConsistent:
            .mostConsistentStat
        }
    }

    var systemImage: String {
        switch self {
        case .bestRound:
            "star.fill"
        case .hotStreak:
            "flame.fill"
        case .biggestLead:
            "crown.fill"
        case .biggestClimb:
            "chart.line.uptrend.xyaxis"
        case .mostConsistent:
            "metronome.fill"
        }
    }

    var tint: Color {
        switch self {
        case .bestRound:
            .orange
        case .hotStreak:
            .red
        case .biggestLead:
            .crown
        case .biggestClimb:
            .green
        case .mostConsistent:
            .blue
        }
    }
}

extension Double {
    /// The spread of a player's scores, such as "±2.5"
    var deviationFormatted: String {
        "±" + formatted(.number.precision(.fractionLength(1)))
    }

    /// An average to at most one decimal place
    var averageFormatted: String {
        formatted(.number.precision(.fractionLength(0...1)))
    }
}

/// A record with who holds it
struct StatHighlight: Identifiable {
    enum Value {
        case points(Int)
        /// From one zero-based rank to another
        case climb(Int, Int)
        case deviation(Double)
    }

    let kind: StatHighlightKind
    let player: Player
    let value: Value
    let detail: LocalizedStringResource?

    var id: String {
        kind.rawValue
    }

    /// The value as VoiceOver reads it
    var spokenValue: String {
        switch value {
        case let .points(points):
            points.formatted(.number)
        case let .climb(lowest, current):
            String(localized: .climbA11YValue((lowest + 1).ordinalFormatted, (current + 1).ordinalFormatted))
        case let .deviation(deviation):
            deviation.deviationFormatted
        }
    }
}

/// A record's icon and title, who holds it, and its value
struct StatHighlightRow: View {
    let highlight: StatHighlight
    let iconSize: CGFloat

    var body: some View {
        let color = highlight.player.color.color

        HStack(spacing: 12) {
            Image(systemName: highlight.kind.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: iconSize, height: iconSize)
                .background(highlight.kind.tint.gradient, in: .rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(highlight.kind.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(highlight.player.name)
                        .fontWeight(.semibold)
                }
            }
            .lineLimit(1)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                value
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(color)
                if let detail = highlight.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(highlight.kind.title))
        .accessibilityValue(
            [highlight.player.name, highlight.spokenValue, highlight.detail.map { String(localized: $0) }]
                .compactMap { $0 }
                .formatted(.list(type: .and, width: .narrow))
        )
        .accessibilityIdentifier("stat-\(highlight.id)")
    }

    @ViewBuilder
    private var value: some View {
        switch highlight.value {
        case let .points(points):
            Text(points.formatted(.number))
        case let .climb(lowest, current):
            // The forward arrow flips for right-to-left languages along with the stack
            HStack(spacing: 4) {
                Text((lowest + 1).ordinalFormatted)
                Image(systemName: "arrow.forward")
                    .font(.caption.weight(.bold))
                Text((current + 1).ordinalFormatted)
            }
        case let .deviation(deviation):
            Text(verbatim: deviation.deviationFormatted)
        }
    }
}

/// A player's total, their round-by-round points, and how they've fared
struct StatsPlayerRow: View {
    let player: Player
    let stats: GameStats<PersistentIdentifier>.PlayerStats
    let isLeader: Bool
    /// The points every player's sparkline spans, so bars compare across players
    let domain: ClosedRange<Int>?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .body) private var avatarSize = 28
    @ScaledMetric(relativeTo: .body) private var sparklineHeight = 36

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top),
                            count: dynamicTypeSize.isAccessibilitySize ? 2 : 4)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                PlayerAvatar(player: player, size: avatarSize)
                Text(player.name)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                if isLeader {
                    CrownBadge()
                        .accessibilityLabel(Text(.leaderA11YValue))
                }
                Spacer(minLength: 8)
                Text(player.total.formatted(.number))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(.leader(isLeader, color: player.color.color))
            }
            .accessibilityElement(children: .combine)
            if let domain, !stats.results.isEmpty {
                sparkline(domain: domain)
                    .frame(height: sparklineHeight)
            }
            LazyVGrid(columns: columns, spacing: 12) {
                statColumn(.averageStat, value: stats.average?.averageFormatted)
                statColumn(.bestStat, value: stats.best?.formatted(.number))
                statColumn(.roundsWonStat, value: stats.roundsWon.formatted(.number))
                statColumn(.roundsLedStat, value: stats.roundsLed.formatted(.number))
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stats-player")
    }

    /// Each complete round's points as a bar, solid where the player won the round
    private func sparkline(domain: ClosedRange<Int>) -> some View {
        let results = stats.results
        let color = player.color.color
        // Plain strings keep these chart labels out of the string catalog
        let roundLabel = String(localized: .rounds)
        let pointsLabel = String(localized: .totalRow)
        // Rounds are categories, so ones the player sat out still leave a gap
        let rounds = results.indices.map { String($0 + 1) }

        return Chart {
            RuleMark(y: .value(pointsLabel, 0))
                .foregroundStyle(.quaternary)
                .lineStyle(StrokeStyle(lineWidth: 1))
            ForEach(results.indices, id: \.self) { index in
                if let points = results[index].points {
                    BarMark(x: .value(roundLabel, rounds[index]),
                            y: .value(pointsLabel, points),
                            width: .ratio(0.7))
                        .foregroundStyle(color.opacity(results[index].won ? 1 : 0.35))
                        .clipShape(.rect(cornerRadius: 2))
                }
            }
        }
        .chartXScale(domain: rounds)
        .chartYScale(domain: domain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .accessibilityHidden(true)
    }

    private func statColumn(_ title: LocalizedStringResource, value: String?) -> some View {
        VStack(spacing: 2) {
            Group {
                if let value {
                    Text(value)
                } else {
                    Dash()
                }
            }
            .font(.headline)
            .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(value ?? "")
    }
}
