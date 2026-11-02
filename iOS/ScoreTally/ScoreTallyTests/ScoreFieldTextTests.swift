//
// ScoreFieldTextTests
// ScoreTallyTests
//
// Created on 2026-10-29
//

import Testing
@testable import ScoreTally

struct ScoreFieldTextTests {
    @Test(arguments: [
        ("", nil),
        ("-", nil),
        ("12", 12),
        ("-12", -12),
        ("\u{2212}7", -7),
        ("١٢", 12),
        ("99999999999999999999", nil)
    ] as [(String, Int?)])
    func parsesTypedText(text: String, expected: Int?) {
        #expect(text.scoreValue == expected)
    }

    @Test func togglingSignBeforeDigitsKeepsTheMinus() {
        let entry = "".togglingScoreSign
        #expect(entry == "-")
        #expect((entry + "5").scoreValue == -5)
        #expect("-5".togglingScoreSign == "5")
    }

    @Test func sanitizingDropsAnythingButTheSignAndDigits() {
        #expect("1,234".sanitizedScoreEntry == "1234")
        #expect("-4a2".sanitizedScoreEntry == "-42")
    }

    @Test(arguments: [0, 15, -3])
    func startingTextRoundTrips(value: Int) {
        #expect(String(scoreEntry: value).scoreValue == value)
    }
}
