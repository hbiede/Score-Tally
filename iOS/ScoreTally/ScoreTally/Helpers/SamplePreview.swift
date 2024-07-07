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
        game2.addPlayer(with: "Alex", score: 10)
        game2.addPlayer(with: "Mom", score: 12)
        game2.addPlayer(with: "Dad", score: 6)
        game2.addPlayer(with: "Derek", score: 3)

        container.mainContext.insert(game2)

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
