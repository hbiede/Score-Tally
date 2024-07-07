//
// RankingEmoji
// ScoreTally 
//
// Created on 7/5/24
//

func getRankingEmoji(for rank: Int, showLossOfPlace: Bool = false) -> String {
    switch rank {
    case 0:
        return "🥇"
    case 1:
        return "🥈"
    case 2:
        return "🥉"
    default:
        return showLossOfPlace ? "❌" : ""
    }
}

