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
    "fr-CA": [
        "games": ["Golf", "Soirée de jeux"],
        "names": ["Félix", "Léa", "William", "Florence"]
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
    ],
    "hi": [
        "games": ["गोल्फ़", "गेम नाइट"],
        "names": ["आरव", "प्रिया", "विवान", "अनन्या"]
    ],
    "ko": [
        "games": ["골프", "게임의 밤"],
        "names": ["민준", "서연", "도윤", "하은"]
    ],
    "nl": [
        "games": ["Golf", "Spelletjesavond"],
        "names": ["Daan", "Emma", "Noah", "Julia"]
    ],
    "pt": [
        "games": ["Golfe", "Noite de jogos"],
        "names": ["Miguel", "Helena", "Arthur", "Alice"]
    ],
    "pt-PT": [
        "games": ["Golfe", "Noite de jogos"],
        "names": ["Santiago", "Leonor", "Francisco", "Matilde"]
    ],
    "ar": [
        "games": ["غولف", "سهرة الألعاب"],
        "names": ["محمد", "مريم", "يوسف", "ليلى"]
    ],
    "he": [
        "games": ["גולף", "ערב משחקים"],
        "names": ["נועה", "דוד", "תמר", "יונתן"]
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

        // Clear existing games, from the list rather than a game the app reopened
        returnToGameList(in: app)
        let deletePredicate = NSPredicate(format: "identifier CONTAINS[c] 'game-'")
        let gamesToDelete = app.buttons.containing(deletePredicate).allElementsBoundByIndex
        gamesToDelete.reversed().forEach {
            $0.press(forDuration: 1)
            deleteGameFromContextMenu(in: app)
        }

        XCTAssert(app.buttons.containing(deletePredicate).firstMatch.waitForNonExistence(timeout: 5))

        // The first game is created empty, then the app opens it, so head back to the list
        guard let gameNames = locale["games"], let playerNames = locale["names"] else {
            XCTFail("Locale is missing names")
            fatalError()
        }
        createGame(in: app, named: gameNames[0])
        returnToGameList(in: app)

        // The game in the screenshots is set up with its players in one go, and opens once it's created
        createGame(in: app, named: gameNames[1], players: playerNames)

        // Set Scores, with the lead changing hands so the round table and race chart have a story
        scoreRound(in: app, with: [1, 3, 0, 2])
        scoreRound(in: app, with: [2, 1, 1, 3])
        scoreRound(in: app, with: [4, 0, 1, 1])
        scoreRound(in: app, with: [3, 1, 0, 0])

        // Tapping players fills an open round, bringing the totals to 11, 5, 2, 7
        let predicatePlayer1 = NSPredicate(format: "identifier CONTAINS[c] 'player-0'")
        app.buttons.containing(predicatePlayer1).firstMatch.tap()
        let predicatePlayer4 = NSPredicate(format: "identifier CONTAINS[c] 'player-3'")
        app.buttons.containing(predicatePlayer4).firstMatch.tap()

        snapshot("1Game")

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

        snapshot("2ScoreAdder")

        // Closing with points typed in asks first
        app.buttons["cancel"].tap()
        app.buttons["discard-changes-button"].firstMatch.tap()

        // Round table
        app.buttons["show-rounds"].tap()

        // The sheet remembers the last mode, so start from the table
        let mode = app.segmentedControls["round-view-mode"]
        mode.buttons.element(boundBy: 0).tap()
        XCTAssert(app.descendants(matching: .any)["round-1"].waitForExistence(timeout: 10))

        snapshot("3RoundTable")

        // Race chart
        mode.buttons.element(boundBy: 1).tap()
        XCTAssert(app.descendants(matching: .any)["race-chart"].waitForExistence(timeout: 10))

        snapshot("4RaceChart")

        mode.buttons.element(boundBy: 0).tap()
        app.buttons["close"].tap()
    }

    @MainActor
    func testRoundTable() throws {
        let app = XCUIApplication()
        app.launch()

        // Clear games left behind by runs that failed before cleaning up, from the list
        // rather than a game the app reopened
        returnToGameList(in: app)
        let leftovers = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Round Table Test'"))
        while leftovers.firstMatch.exists {
            leftovers.firstMatch.press(forDuration: 1)
            deleteGameFromContextMenu(in: app)
        }

        // Newest games list first, so the new game is game-0. Creating it opens it.
        createGame(in: app, named: "Round Table Test")
        let game = app.buttons.containing(NSPredicate(format: "identifier CONTAINS[c] 'game-0'")).firstMatch

        // Players added one at a time from the game
        for name in ["Adam", "Elijah", "Brooke", "Aiden", "Charlotte"] {
            app.buttons["add-player"].tap()
            app.typeText(name)
            app.buttons["create-player-button-title"].firstMatch.tap()
        }

        XCTAssertFalse(app.descendants(matching: .any)["round-1"].exists)
        XCTAssertFalse(app.buttons["show-rounds"].exists)
        scoreRound(in: app, with: [3, 5, 2, 0, 4])
        scoreRound(in: app, with: [4, 7, -1, 3, 1])
        app.buttons.containing(NSPredicate(format: "identifier CONTAINS[c] 'player-0'")).firstMatch.tap()

        app.buttons["show-rounds"].tap()

        // The sheet remembers the last mode, so start from the table
        let mode = app.segmentedControls["round-view-mode"]
        mode.buttons.element(boundBy: 0).tap()

        let rows = app.descendants(matching: .any)
        XCTAssert(rows["round-1"].waitForExistence(timeout: 10))
        XCTAssert(rows["round-2"].exists)
        XCTAssert(rows["round-3"].exists)
        XCTAssertFalse(rows["round-4"].exists)
        XCTAssertFalse(rows["round-earlier"].exists)
        XCTAssert(rows["round-total"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Round table"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Tapping a round fixes its points: Brooke's -1 in round 2 becomes 6
        rows["round-2"].tap()
        let brooke = app.textFields["round-input-2"]
        XCTAssert(brooke.waitForExistence(timeout: 2))
        brooke.tap()
        brooke.clearAndType("6", in: app)
        app.buttons["save-round-button-title"].tap()
        XCTAssert(rows["round-2"].waitForExistence(timeout: 2))
        XCTAssert((rows["round-2"].value as? String)?.contains("Brooke: 6") == true)

        // The open round can be deleted from its context menu once that's confirmed
        rows["round-3"].press(forDuration: 1)
        app.buttons["delete-round-right-click-action"].tap()
        app.buttons["delete-round-confirmation-button"].firstMatch.tap()
        XCTAssertFalse(rows["round-3"].waitForExistence(timeout: 1))
        XCTAssert(rows["round-2"].exists)

        // Five players are too wide for a phone, so the table scrolls sideways
        app.scrollViews.firstMatch.swipeLeft()
        let scrolled = XCTAttachment(screenshot: app.screenshot())
        scrolled.name = "Round table scrolled"
        scrolled.lifetime = .keepAlways
        add(scrolled)

        // The race chart shows the same game as lines
        mode.buttons.element(boundBy: 1).tap()
        XCTAssert(rows["race-chart"].waitForExistence(timeout: 10))
        let race = XCTAttachment(screenshot: app.screenshot())
        race.name = "Race chart"
        race.lifetime = .keepAlways
        add(race)

        // Drag across the chart to read everyone's totals at a round
        let chart = rows["race-chart"].firstMatch
        chart.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.5, thenDragTo: chart.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.5)))
        let selected = XCTAttachment(screenshot: app.screenshot())
        selected.name = "Race chart selection"
        selected.lifetime = .keepAlways
        add(selected)

        // The stats tab finds round 2's top score and lists every player
        mode.buttons.element(boundBy: 2).tap()
        XCTAssert(rows["round-stats"].waitForExistence(timeout: 2))
        XCTAssert((rows["stat-best-round"].value as? String)?.contains("Round 2") == true)
        XCTAssertEqual(rows.matching(identifier: "stats-player").count, 5)
        let stats = XCTAttachment(screenshot: app.screenshot())
        stats.name = "Round stats"
        stats.lifetime = .keepAlways
        add(stats)

        mode.buttons.element(boundBy: 0).tap()

        // Clean up so repeated runs don't pile up games
        app.buttons["close"].tap()
        returnToGameList(in: app)
        game.press(forDuration: 1)
        deleteGameFromContextMenu(in: app)
    }

    /// Creates a game from the New Game sheet, which opens it
    @MainActor
    private func createGame(in app: XCUIApplication, named name: String, players: [String] = []) {
        app.buttons["add-game"].tap()
        // The name field starts focused
        app.typeText(name)
        for player in players {
            // Each new row takes focus
            app.buttons["new-game-add-player"].tap()
            app.typeText(player)
        }
        let createButton = app.buttons["create-game-button-title"].firstMatch
        createButton.tap()
        // A tap can miss on iPhone Duo, where the sheet's toolbar buttons sit by the hinge
        if !app.textFields["new-game-name"].waitForNonExistence(timeout: 2) {
            createButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        // The sheet covers the list while it dismisses
        XCTAssertTrue(app.textFields["new-game-name"].waitForNonExistence(timeout: 10))
    }

    /// On iPhone the game list is behind the open game, but on iPad it stays in the sidebar,
    /// where the first navigation bar button is Add Game rather than Back
    @MainActor
    private func returnToGameList(in app: XCUIApplication) {
        if !app.buttons["add-game"].waitForHittable(timeout: 2) {
            // iPhone Duo doesn't report the back button as part of the navigation bar
            let back = app.buttons["BackButton"].exists ? app.buttons["BackButton"] : app.navigationBars.buttons.firstMatch
            XCTAssertTrue(back.waitForExistence(timeout: 10))
            back.tap()
        }
    }

    /// Deletes a game from its open context menu, confirming the deletion
    @MainActor
    private func deleteGameFromContextMenu(in app: XCUIApplication) {
        app.buttons["delete-game-right-click-action"].tap()
        app.buttons["delete-game-confirmation-button"].firstMatch.tap()
    }

    @MainActor
    private func scoreRound(in app: XCUIApplication, with points: [Int]) {
        app.buttons["score-round"].tap()
        for (index, value) in points.enumerated() {
            let field = app.textFields["player-input-\(index)"]
            field.tap()
            field.clearAndType(String(value), in: app)
        }
        app.buttons["save-round-button-title"].tap()
    }
}

private extension XCUIElement {
    func waitForHittable(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isHittable { return true }
            usleep(100_000)
        }
        return isHittable
    }

    /// Replaces the text of a field that was just tapped. It's typed through the app, since a SwiftUI field
    /// can show its cursor without reporting keyboard focus itself, which makes typing into the element fail.
    func clearAndType(_ text: String, in app: XCUIApplication) {
        let existing = (value as? String) ?? ""
        app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + text)
    }
}
