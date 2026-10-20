//
// RankingEmoji
// ScoreTally
//
// Created on 7/5/24
//

extension Int? {
    /// The medal for a zero-based place, or a cross for anyone out of the medals when `showLossOfPlace` is set
    func rankingEmoji(showLossOfPlace: Bool = false) -> String {
        switch self {
        case 0?:
            "🥇"
        case 1?:
            "🥈"
        case 2?:
            "🥉"
        default:
            showLossOfPlace ? "❌" : ""
        }
    }
}
