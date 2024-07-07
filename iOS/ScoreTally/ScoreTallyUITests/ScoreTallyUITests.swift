//
// ScoreTallyUITests
// ScoreTallyUITests 
//
// Created on 7/5/24
//

import XCTest

let names = [
    "en": [
        "games": ["Golf", "Game Night"],
        "names": ["Adam", "Elijah", "Brooke", "Aiden"]
    ],
    "es": [
        "games": ["Golf", "Noche de juegos"],
        "names": ["Lucas", "Gabriel", "Sofia", "Daniel"]
    ],
    "fr-FR": [
        "games": ["Golf", "Soirée jeu"],
        "names": ["Jade", "Gabriel", "Léo", "Emma"]
    ],
    "de-DE": [
        "games": ["Golf", "Spielnacht"],
        "names": ["Finn", "Emma", "Angela", "Leon"]
    ],
    "it": [
        "games": ["Golf", "Serata di gioco"],
        "names": ["Aurora", "Gabriele", "Sofia", "Federico"]
    ],
    "ja": [
        "games": ["ゴルフ", "ゲームナイト"],
        "names": ["凛", "律", "暖", "芽依"]
    ],
    "ru": [
        "games": ["Гольф", "Ночь игр"],
        "names": ["Евгений", "Анастасия", "София", "Михаил"]
    ],
    "zh-Hans": [
        "games": ["高尔夫球", "比赛之夜"],
        "names": ["强", "爱", "雅", "博"]
    ],
    "zh-Hant": [
        "games": ["高爾夫球", "比賽之夜"],
        "names": ["家豪", "淑芬", "俊宏", "美惠"]
    ]
]

final class ScoreTallyUITests: XCTestCase {

    @MainActor
    override func setUpWithError() throws {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testSnapshots() throws {

        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        app.activate()

        guard let id = Snapshot.deviceLanguage.split(separator: /[_-]/).first?.description else {
            XCTFail("Locale does not have language code")
            fatalError()
        }

        guard let locale = names[Snapshot.deviceLanguage] ?? names[id] else {
            XCTFail("Locale not found: \(id)")
            fatalError()
        }

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        // Clear existing games
        let deletePredicate = NSPredicate(format: "identifier CONTAINS[c] 'game-'")
        let gamesToDelete = app.buttons.containing(deletePredicate).allElementsBoundByIndex
        gamesToDelete.reversed().forEach {
            $0.press(forDuration: 1)
            app.buttons["delete-game-right-click-action"].tap()
        }

        XCTAssert(!app.buttons.containing(deletePredicate).firstMatch.exists)

        locale["games"]?.forEach { name in
            app.buttons["add-game"].tap()
            app.typeText(name)
            app.buttons["create-game-button-title"].tap()
        }

        snapshot("1Menu")

        // Create a game
        let predicate = NSPredicate(format: "identifier CONTAINS[c] 'game-0'")
        app.buttons.containing(predicate).firstMatch.tap()

        app.tap()

        locale["names"]?.forEach { name in
            app.buttons["add-player"].tap()
            app.typeText(name)
            app.buttons["create-player-button-title"].tap()
        }

        // Set Scores
        let predicatePlayer1 = NSPredicate(format: "identifier CONTAINS[c] 'player-0'")
        let player1Button = app.buttons.containing(predicatePlayer1).firstMatch
        for _ in 1..<12 {
            player1Button.tap()
        }
        let predicatePlayer2 = NSPredicate(format: "identifier CONTAINS[c] 'player-1'")
        let player2Button = app.buttons.containing(predicatePlayer2).firstMatch
        for _ in 1..<6 {
            player2Button.tap()
        }
        let predicatePlayer3 = NSPredicate(format: "identifier CONTAINS[c] 'player-2'")
        let player3Button = app.buttons.containing(predicatePlayer3).firstMatch
        for _ in 1..<3 {
            player3Button.tap()
        }
        let predicatePlayer4 = NSPredicate(format: "identifier CONTAINS[c] 'player-3'")
        let player4Button = app.buttons.containing(predicatePlayer4).firstMatch
        for _ in 1..<8 {
            player4Button.tap()
        }

        snapshot("2Game")

        // Score adder
        app.buttons["score-round"].tap()

        let textFields = app.textFields.allElementsBoundByIndex
        textFields[0].tap()
        app.typeText("2")
        textFields[1].tap()
        app.typeText("4")
        textFields[2].tap()
        app.typeText("1")

        app.staticTexts.containing(predicatePlayer4).firstMatch.tap()

        snapshot("3ScoreAdder")

        app.buttons["cancel"].tap()
    }
}
