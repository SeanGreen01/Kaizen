import XCTest

final class KaizenUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func launchCalendar() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-calendar"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Priorities"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor func testCreateEventAndChangeSelectedDay() throws {
        let app = launchCalendar()
        app.buttons["Agenda"].tap()
        XCTAssertTrue(app.staticTexts["Morning"].waitForExistence(timeout: 5))
        app.buttons["Add calendar event"].tap()
        let title = app.descendants(matching: .any)["eventTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("Dentist appointment")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Dentist appointment")).firstMatch.waitForExistence(timeout: 5))
        app.buttons[dayIdentifier(offset: 1)].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Design review")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Dentist appointment")).firstMatch.exists)
        app.buttons[dayIdentifier(offset: 0)].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Dentist appointment")).firstMatch.exists)
    }

    @MainActor func testReviewChooseTasksAndScheduleTomorrow() throws {
        let app = launchCalendar()
        app.swipeUp()
        let plan = app.buttons["beginPlanning"]
        XCTAssertTrue(plan.waitForExistence(timeout: 5))
        plan.tap()
        app.buttons["Choose tomorrow’s tasks →"].tap()
        let walk = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Morning walk")).firstMatch
        XCTAssertTrue(walk.waitForExistence(timeout: 5))
        walk.tap()
        app.buttons["Schedule your day →"].tap()
        XCTAssertTrue(app.navigationBars["03 / Schedule"].waitForExistence(timeout: 5))
        app.swipeUp()
        let untimedWalk = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Morning walk")).firstMatch
        untimedWalk.tap()
        XCTAssertTrue(app.navigationBars["Schedule task"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.buttons["Save tomorrow’s plan"].tap()
        XCTAssertTrue(app.buttons[dayIdentifier(offset: 1)].waitForExistence(timeout: 5))
        app.buttons[dayIdentifier(offset: 1)].tap()
        app.swipeDown()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Morning walk")).firstMatch.waitForExistence(timeout: 5))
    }

    private func dayIdentifier(offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "day-%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
}
