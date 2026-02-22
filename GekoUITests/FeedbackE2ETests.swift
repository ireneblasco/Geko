//
//  FeedbackE2ETests.swift
//  GekoUITests
//
//  End-to-end tests for the feedback prompt feature.
//

import XCTest

final class FeedbackE2ETests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Creates 4 habits, completes each, and verifies the feedback sheet appears.
    @MainActor
    func testFeedbackSheetAppearsAfterFourCompletions() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--resetFeedbackState"]
        app.launch()

        // 1. Create 4 habits
        for i in 1...4 {
            app.buttons["add_habit_button"].tap()

            let nameField = app.textFields["habit_name_field"]
            XCTAssertTrue(nameField.waitForExistence(timeout: 3))
            nameField.tap()
            nameField.typeText("Feedback Habit \(i)")

            app.buttons["habit_editor_add"].tap()

            XCTAssertTrue(app.staticTexts["Feedback Habit \(i)"].waitForExistence(timeout: 3))
        }

        // 2. Complete each habit (tap completion button for each)
        let completionButtonsQuery = app.buttons.matching(identifier: "habit_completion")
        XCTAssertTrue(completionButtonsQuery.firstMatch.waitForExistence(timeout: 2))

        for i in 0..<4 {
            completionButtonsQuery.element(boundBy: i).tap()
        }

        // 3. Verify feedback sheet appears
        let enjoyText = app.staticTexts["Are you enjoying Geko?"]
        let sheetExists = enjoyText.waitForExistence(timeout: 3)
        XCTAssertTrue(sheetExists, "Feedback sheet should appear after completing 4 habits")
    }

    /// Completes 4 habits, taps Yes, verifies sheet dismisses.
    @MainActor
    func testFeedbackSheet_yesPath_dismisses() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--resetFeedbackState"]
        app.launch()

        // Create and complete 4 habits
        for i in 1...4 {
            app.buttons["add_habit_button"].tap()
            let nameField = app.textFields["habit_name_field"]
            XCTAssertTrue(nameField.waitForExistence(timeout: 3))
            nameField.tap()
            nameField.typeText("Yes Path Habit \(i)")
            app.buttons["habit_editor_add"].tap()
            XCTAssertTrue(app.staticTexts["Yes Path Habit \(i)"].waitForExistence(timeout: 3))
        }

        let completionButtonsQuery = app.buttons.matching(identifier: "habit_completion")
        for i in 0..<4 {
            completionButtonsQuery.element(boundBy: i).tap()
        }

        // Wait for sheet and tap Yes
        let yesButton = app.buttons["Yes"]
        XCTAssertTrue(yesButton.waitForExistence(timeout: 3))
        yesButton.tap()

        // Tap Leave Review to dismiss (triggers requestReview and dismisses)
        let leaveReviewButton = app.buttons["Leave Review"]
        XCTAssertTrue(leaveReviewButton.waitForExistence(timeout: 2))
        leaveReviewButton.tap()

        // Sheet should dismiss; main list with add button is visible
        let addHabitButton = app.buttons["add_habit_button"]
        XCTAssertTrue(addHabitButton.waitForExistence(timeout: 3))
    }
}
