//
// GameViewPlayerCellView
// ScoreTally
//
// Created on 7/5/24
//

import SwiftData
import SwiftUI

struct GameViewPlayerCellView: View {

    private var player: Player
    /// The player's place, which the grid works out for every card at once
    private let place: Int?
    /// Whether the player is in first place without anyone tying them
    private let leadsAlone: Bool

    /// Counts each time the player takes the lead, so the card can celebrate it
    @State private var leadsTaken = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingCustomIncrementMenu = false
    @State private var addingScore = 0

    @State private var showingEditSheet = false
    @State private var showingResetConfirmation = false
    @State private var showingDeleteConfirmation = false

    @ScaledMetric(relativeTo: .headline) private var avatarSize = 28

    private var rankingEmoji: String {
        place.rankingEmoji()
    }

    private var accessibilityValue: String {
        [
            String(localized: .playerScoreA11YValue(player.total)),
            place.map { String(localized: .playerRankA11YValue($0 + 1)) }
        ]
        .compactMap { $0 }
        .formatted(.list(type: .and, width: .narrow))
    }

    init(for player: Player, place: Int?, leadsAlone: Bool) {
        self.player = player
        self.place = place
        self.leadsAlone = leadsAlone
    }

    var body: some View {
        // Copies for the celebrations, whose animation closures can't reach the view's properties
        let color = player.color.color
        let reduceMotion = self.reduceMotion
        let cornerRadius = PlayerCardButtonStyle.cornerRadius
        Button(action: onPress) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    PlayerAvatar(player: player, size: avatarSize)
                    Text(player.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !rankingEmoji.isEmpty {
                        Text(rankingEmoji)
                            .font(.title2)
                            .keyframeAnimator(
                                initialValue: MedalCelebration(),
                                trigger: leadsTaken
                            ) { medal, celebration in
                                medal
                                    .scaleEffect(reduceMotion ? 1 : celebration.scale)
                                    .rotationEffect(reduceMotion ? .zero : celebration.tilt)
                            } keyframes: { _ in
                                KeyframeTrack(\.scale) {
                                    SpringKeyframe(1.5, duration: 0.2, spring: .snappy)
                                    SpringKeyframe(1, duration: 0.6, spring: .bouncy)
                                }
                                KeyframeTrack(\.tilt) {
                                    CubicKeyframe(.degrees(-15), duration: 0.12)
                                    CubicKeyframe(.degrees(15), duration: 0.16)
                                    CubicKeyframe(.degrees(-8), duration: 0.14)
                                    CubicKeyframe(.zero, duration: 0.14)
                                }
                            }
                    }
                }
                scoreText
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlayerCardButtonStyle(color: color, isLeading: place == 0))
        .contentShape(.contextMenuPreview, .rect(cornerRadius: cornerRadius))
        .keyframeAnimator(initialValue: CardCelebration(), trigger: leadsTaken) { card, celebration in
            card
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(color)
                        .blur(radius: PlayerCardButtonStyle.shadowBlur * 4)
                        .opacity(celebration.glow)
                }
                .scaleEffect(reduceMotion ? 1 : celebration.scale)
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                SpringKeyframe(1.06, duration: 0.18, spring: .snappy)
                SpringKeyframe(1, duration: 0.5, spring: .bouncy)
            }
            KeyframeTrack(\.glow) {
                LinearKeyframe(0.9, duration: 0.15)
                LinearKeyframe(0.9, duration: 0.4)
                CubicKeyframe(0, duration: 0.7)
            }
        }
        .onChange(of: leadsAlone) { ledAlone, nowLeadsAlone in
            if nowLeadsAlone && !ledAlone {
                leadsTaken += 1
            }
        }
        // One haptic per change, so taking the lead plays its own instead of the score's
        .sensoryFeedback(trigger: HapticState(total: player.total, leadsAlone: leadsAlone)) { old, new in
            if new.leadsAlone && !old.leadsAlone {
                return .success
            }
            guard new.total != old.total else {
                return nil
            }
            return new.total > old.total ? .increase : .decrease
        }
        .contextMenu {
            Section {
                Button(.deletePlayerRightClickAction, role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .accessibilityIdentifier("delete-player-right-click-action")
                Button(.editPlayerRightClickAction) {
                    showingEditSheet = true
                }
                .accessibilityIdentifier("edit-player-right-click-action")
            }

            Menu(.incrementRightClickSectionTitle, content: {
                ForEach([1, 5, 10, 25, 100], id: \.self) { increment in
                    incrementMenuButton(for: increment)
                }
                Button(.incrementByCustomAmountRightClickButton) {
                    addCustomScore()
                }
            }, primaryAction: {
                player.increment()
            })
            Button(.resetScoreRightClickButton) {
                showingResetConfirmation = true
            }
            .disabled(!player.canResetScore)
        }
        .sheet(isPresented: $showingEditSheet) {
            PlayerEditView(editing: player)
                .presentationSizing(.form)
        }
        .confirmationDialog(
            Text(.deletePlayerConfirmationTitle(player.name)),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(.deleteConfirmationButton, role: .destructive) {
                withAnimation {
                    player.delete()
                }
            }
            .accessibilityIdentifier("delete-player-confirmation-button")
            Button(.cancel, role: .cancel) {}
        } message: {
            Text(.deletePlayerConfirmationMessage)
        }
        .alert(.addToScoreTitle, isPresented: $showingCustomIncrementMenu) {
            TextField(value: $addingScore, format: .number) {
                Text(.addToScorePlaceholder)
            }
            .keyboardType(.numbersAndPunctuation)

            Button(.cancel, role: .cancel) {
                showingCustomIncrementMenu = false
            }
            Button(.addToScoreButtonTitle) {
                withAnimation {
                    player.increment(by: addingScore)
                }
            }
        }
        .confirmationDialog(
            Text(.resetScoreConfirmationTitle(player.name)),
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(.resetScoreConfirmationButton, role: .destructive) {
                player.resetScore()
            }
            .accessibilityIdentifier("reset-score-confirmation-button")
            Button(.cancel, role: .cancel) {}
        } message: {
            Text(.resetScoreConfirmationMessage)
        }
        .accessibilityLabel(player.name)
        .accessibilityValue(accessibilityValue)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                player.increment()
            case .decrement:
                player.increment(by: -1)
            @unknown default:
                break
            }
        }
        .accessibilityIdentifier(player.name)
    }

    private var scoreText: some View {
        Text(player.total.formatted(.number))
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(.numericText(value: Double(player.total)))
            .animation(.snappy, value: player.total)
    }

    private func addCustomScore() {
        showingCustomIncrementMenu = true
        addingScore = 0
    }

    private func incrementMenuButton(for increment: Int) -> some View {
        Button(.incrementByRightClickButton(increment)) {
            player.increment(by: increment)
        }
    }

    private func onPress() {
        player.increment()
    }
}

/// What the card's haptics respond to
private struct HapticState: Equatable {
    let total: Int
    let leadsAlone: Bool
}

/// The pop and glow a card plays when its player takes the lead
private struct CardCelebration {
    var scale = 1.0
    var glow = 0.0
}

/// The bounce and wiggle the medal plays when its player takes the lead
private struct MedalCelebration {
    var scale = 1.0
    var tilt = Angle.zero
}

/// A card tinted in the player's color that shrinks while pressed, outlined while they lead
private struct PlayerCardButtonStyle: ButtonStyle {
    static let shadowBlur: CGFloat = 4
    static let cornerRadius: CGFloat = 20

    let color: Color
    let isLeading: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
        configuration.label
            .background {
                shape
                    .fill(.background.secondary)
                    .overlay {
                        shape.fill(color.opacity(configuration.isPressed ? 0.3 : 0.16))
                    }
                    .shadow(color: isLeading ? color : .clear, radius: Self.shadowBlur)
            }
            .overlay {
                shape.strokeBorder(color.opacity(isLeading ? 1 : 0.25), lineWidth: isLeading ? 2 : 1)
            }
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

#if DEBUG
import SwiftData

#Preview(traits: .sampleData) {
    @Previewable @Query var players: [Player] = [Player]()
    GameViewPlayerCellView(for: players.first!, place: 0, leadsAlone: true)
}
#endif
