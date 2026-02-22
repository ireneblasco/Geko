//
//  ScreenshotTests.swift
//  GekoUITests
//
//  Captures screenshots of home screen and add-habit form for App Store / marketing.
//  Run via: ./Scripts/capture-screenshots.sh
//

import XCTest

final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Bootstraps sample habits (via launch arg), hides debug button, captures home and add-habit screenshots.
    @MainActor
    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--isPlusForScreenshots", "--bootstrapSampleHabitsForScreenshots"]
        app.launch()

        // 1. Wait for habits to appear (bootstrapped on launch)
        sleep(2)  // Allow bootstrap to complete
        XCTAssertTrue(app.staticTexts["Drink Water"].waitForExistence(timeout: 8), "Drink Water habit should appear")
        sleep(1)

        // 2. Capture home screen screenshot (debug button already hidden)
        let outputDir = screenshotOutputDirectory()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        let homeScreenshot = app.screenshot()
        let homeURL = outputDir.appendingPathComponent("home-with-habits.png")
        try homeScreenshot.pngRepresentation.write(to: homeURL)

        // 3. Tap Add Habit and capture add-habit form
        app.buttons["add_habit_button"].tap()
        let nameField = app.textFields["habit_name_field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Add habit form should appear")
        sleep(1)

        let addFormScreenshot = app.screenshot()
        let addFormURL = outputDir.appendingPathComponent("add-habit-form.png")
        try addFormScreenshot.pngRepresentation.write(to: addFormURL)

        // 4. Dismiss the sheet (tap Cancel)
        app.buttons["Cancel"].tap()
    }

    private func screenshotOutputDirectory() -> URL {
        if let envDir = ProcessInfo.processInfo.environment["SCREENSHOT_OUTPUT_DIR"],
           !envDir.isEmpty {
            return URL(fileURLWithPath: envDir)
        }
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("geko_screenshots")
    }
}
