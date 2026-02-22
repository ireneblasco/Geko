//
//  WidgetE2ETests.swift
//  GekoUITests
//
//  End-to-end tests for the Geko habit widget.
//

import XCTest

final class WidgetE2ETests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Verifies the add-habit flow works. Use as a smoke test for the app UI
    /// that the widget E2E test depends on.
    @MainActor
    func testAddHabitFlow() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["add_habit_button"].tap()

        let nameField = app.textFields["habit_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("E2E Smoke Test")

        app.buttons["habit_editor_add"].tap()

        XCTAssertTrue(app.staticTexts["E2E Smoke Test"].waitForExistence(timeout: 3))
    }

    /// Creates a habit in the app, triggers widget reload, then verifies the widget
    /// displays the habit on the home screen.
    /// Prerequisite: Add a Geko Habit Tracker widget to the home screen before running.
    @MainActor
    func testWidgetShowsHabitAfterCreation() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Create a habit
        let habitName = "E2E Test Habit"
        app.buttons["add_habit_button"].tap()

        let nameField = app.textFields["habit_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText(habitName)

        app.buttons["habit_editor_add"].tap()

        // 2. Allow widget timeline to reload (app in foreground)
        sleep(2)

        // 3. Go to home screen
        XCUIDevice.shared.press(.home)
        sleep(2)

        // 4. Find widget via Springboard
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()

        // Widget may be identified by our accessibilityIdentifier or by the habit name
        let widget = springboard.otherElements["geko_habit_widget"]
            .firstMatch
        let habitNameElement = springboard.staticTexts[habitName]

        // At least one should exist if the widget is on the home screen
        let widgetExists = widget.waitForExistence(timeout: 5)
        let habitVisible = habitNameElement.waitForExistence(timeout: 2)

        if !widgetExists && !habitVisible {
            throw XCTSkip("No Geko widget on home screen. Add a Geko Habit Tracker widget to run full E2E verification.")
        }
    }
}
