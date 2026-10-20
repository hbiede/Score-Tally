//
// SamplePreview
// ScoreTally
//
// Created on 7/5/24
//

#if DEBUG
import SwiftUI
import SwiftData

// Make preview data using traits
struct SampleData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Game.self, configurations: config)

        let game1 = Game(name: "Test Game", createdDate: Date(timeIntervalSince1970: 1720216272))
        game1.addPlayer(with: "Adam")
        game1.addPlayer(with: "Sarah")
        game1.addPlayer(with: "Aiden")
        game1.addPlayer(with: "Sally")

        container.mainContext.insert(game1)

        let game2 = Game(name: "Family Game Night", createdDate: Date(timeIntervalSince1970: 1720214245))
        // Inserted first so the players and rounds land in the context
        container.mainContext.insert(game2)
        let alex = game2.addPlayer(with: "Alex")
        let mom = game2.addPlayer(with: "Mom")
        let dad = game2.addPlayer(with: "Dad")
        let derek = game2.addPlayer(with: "Derek")
        game2.completeRound(with: [(alex, 3), (mom, 5), (dad, 2), (derek, 0)])
        game2.completeRound(with: [(alex, 4), (mom, 7), (dad, 4), (derek, 3)])
        alex.increment(by: 3)

        // A long name and a crowd, to check the title and grid don't clip
        let game3 = Game(
            name: "Saturday Night Board Game Championship",
            createdDate: Date(timeIntervalSince1970: 1720210000)
        )
        container.mainContext.insert(game3)
        let players = ["Alexandria", "Bartholomew Montgomery", "Chris", "Dee", "Eli", "Fran"].map {
            game3.addPlayer(with: $0)
        }
        // Chris and Dee tie for second
        game3.completeRound(with: zip(players, [12, 4, 9, 7, 1, 0]))
        game3.completeRound(with: zip(players, [15, 6, 8, 10, 2, 0]))

        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var sampleData: Self = .modifier(SampleData())
}
#endif
