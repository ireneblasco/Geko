//
//  FeedbackTests.swift
//  GekoTests
//
//  Unit tests for the feedback feature: FeedbackManager, FeedbackSheetView, NotionFeedbackService.
//

import SwiftData
import SwiftUI
import Testing
import ViewInspector
import GekoShared
@testable import Geko

struct FeedbackTests {

    // MARK: - FeedbackManager

    @Test @MainActor func feedbackManager_doesNotTrigger_beforeFourthHabit() throws {
        FeedbackManager.shared.resetForTesting()

        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        FeedbackManager.shared.setModelContext(context)

        // Create 3 habits and complete each for today
        for i in 1...3 {
            let habit = Habit(name: "Habit \(i)", emoji: "✅", color: .blue, dailyTarget: 1)
            context.insert(habit)
            habit.incrementCompletion()
        }
        try context.save()

        // Record completion of 3rd habit (only 3 completed)
        let thirdHabit = try context.fetch(FetchDescriptor<Habit>()).first { $0.name == "Habit 3" }!
        FeedbackManager.shared.recordCompletion(habit: thirdHabit, date: Date())

        #expect(!FeedbackManager.shared.shouldShowFeedbackSheet)
    }

    @Test @MainActor func feedbackManager_triggers_afterFourthHabit() throws {
        FeedbackManager.shared.resetForTesting()

        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        FeedbackManager.shared.setModelContext(context)

        // Create 4 habits and complete each for today
        for i in 1...4 {
            let habit = Habit(name: "Habit \(i)", emoji: "✅", color: .blue, dailyTarget: 1)
            context.insert(habit)
            habit.incrementCompletion()
        }
        try context.save()

        let fourthHabit = try context.fetch(FetchDescriptor<Habit>()).first { $0.name == "Habit 4" }!
        FeedbackManager.shared.recordCompletion(habit: fourthHabit, date: Date())

        #expect(FeedbackManager.shared.shouldShowFeedbackSheet)
    }

    @Test @MainActor func feedbackManager_doesNotTrigger_ifAlreadyAsked() throws {
        FeedbackManager.shared.resetForTesting()
        FeedbackManager.shared.markSheetPresented()

        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        FeedbackManager.shared.setModelContext(context)

        for i in 1...4 {
            let habit = Habit(name: "Habit \(i)", emoji: "✅", color: .blue, dailyTarget: 1)
            context.insert(habit)
            habit.incrementCompletion()
        }
        try context.save()

        let fourthHabit = try context.fetch(FetchDescriptor<Habit>()).first { $0.name == "Habit 4" }!
        FeedbackManager.shared.recordCompletion(habit: fourthHabit, date: Date())

        #expect(!FeedbackManager.shared.shouldShowFeedbackSheet)
    }

    @Test @MainActor func feedbackManager_doesNotTrigger_forPastDate() throws {
        FeedbackManager.shared.resetForTesting()

        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        FeedbackManager.shared.setModelContext(context)

        let habit = Habit(name: "Habit", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        habit.incrementCompletion()
        try context.save()

        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
        habit.toggleCompleted(on: yesterday, calendar: calendar)
        try context.save()

        // Simulate completion for yesterday (4 habits completed yesterday - but we pass yesterday)
        FeedbackManager.shared.recordCompletion(habit: habit, date: yesterday)

        #expect(!FeedbackManager.shared.shouldShowFeedbackSheet)
    }

    // MARK: - FeedbackSheetView

    @Test @MainActor func feedbackSheetView_showsInitialQuestion() throws {
        let view = FeedbackSheetView(onDismiss: {})

        let text = try view.inspect().find(text: "Are you enjoying Geko?")
        #expect(try text.string() == "Are you enjoying Geko?")
    }

    @Test @MainActor func feedbackSheetView_yesButton_exists() throws {
        let view = FeedbackSheetView(onDismiss: {})

        let yesButton = try view.inspect().find(button: "Yes")
        try yesButton.tap()
    }

    @Test @MainActor func feedbackSheetView_noButton_revealsTextField() throws {
        let view = FeedbackSheetView(onDismiss: {})

        let noButton = try view.inspect().find(viewWithAccessibilityIdentifier: "feedback_no")
        try noButton.button().tap()

        _ = try view.inspect().find(viewWithAccessibilityIdentifier: "feedback_textfield")
    }

    // MARK: - NotionFeedbackService

    @Test func notionFeedbackService_throwsWhenSecretsMissing() async throws {
        let service = NotionFeedbackService(token: nil, databaseId: nil)

        await #expect(throws: NotionError.missingSecrets) {
            try await service.submit(feedback: "test feedback")
        }
    }

    @Test func notionFeedbackService_throwsWhenTokenEmpty() async throws {
        let service = NotionFeedbackService(token: "", databaseId: "some-db-id")

        await #expect(throws: NotionError.missingSecrets) {
            try await service.submit(feedback: "test feedback")
        }
    }
}
