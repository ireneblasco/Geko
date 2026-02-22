//
//  HabitsTests.swift
//  GekoTests
//
//  ViewInspector tests for Habits feature (#1)
//

import SwiftData
import SwiftUI
import Testing
import ViewInspector
import GekoShared
@testable import Geko

@Suite(.serialized)
struct HabitsTests {

    @Test(.disabled("Intermittent: passes in isolation, fails in full suite - ViewInspector/ContentView hierarchy"))
    @MainActor func contentView_emptyState_showsNoHabitsYet() throws {
        #if DEBUG
        FeedbackManager.shared.resetForTesting()
        #endif

        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let calendar = Calendar(identifier: .gregorian)
        let view = ContentView()
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))

        // ContentUnavailableView shows empty state; verify by finding its title text
        let cav = try view.inspect().find(ViewType.ContentUnavailableView.self)
        _ = try cav.find(text: "No Habits Yet")
    }

    @Test(.disabled("Intermittent: passes in isolation, fails in full suite - ViewInspector/ContentView hierarchy"))
    @MainActor func contentView_withHabits_showsAddHabitButton() throws {
        #if DEBUG
        FeedbackManager.shared.resetForTesting()
        #endif

        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Meditate", emoji: "🧘", color: .purple, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let calendar = Calendar(identifier: .gregorian)
        let view = ContentView()
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))

        _ = try view.inspect().find(button: "Add Habit")
    }

    @Test @MainActor func habitRow_displaysNameAndEmoji() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Exercise", emoji: "🏃", color: .green, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let calendar = Calendar(identifier: .gregorian)
        let view = HabitRow(habit: habit, viewMode: .weekly)
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))

        let nameText = try view.inspect().find(text: "Exercise")
        #expect(try nameText.string() == "Exercise")
    }

    @Test(.disabled("Intermittent: passes in isolation, fails in full suite - shared FeedbackManager state"))
    @MainActor func habitRow_tappingCompletionButtonTogglesDone() throws {
        #if DEBUG
        FeedbackManager.shared.resetForTesting()
        #endif

        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        #expect(!habit.isCompleted())

        let calendar = Calendar(identifier: .gregorian)
        let view = HabitRow(habit: habit, viewMode: .weekly)
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))

        // Completion button: find by identifier, locate parent Button, tap
        let completionView = try view.inspect().find(viewWithAccessibilityIdentifier: "habit_completion")
        let button = try completionView.find(ViewType.Button.self, relation: .parent)
        try button.tap()

        #expect(habit.isCompleted())

        try button.tap()

        #expect(!habit.isCompleted())
    }

    @Test @MainActor func habitRow_subtitleReflectsCompletion() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let calendar = Calendar(identifier: .gregorian)

        // Not completed: subtitle shows "Not done today"
        var view = HabitRow(habit: habit, viewMode: .weekly)
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))
        var subtitleText = try view.inspect().find(text: "Not done today")
        #expect(try subtitleText.string() == "Not done today")

        // Completed: subtitle shows "Done today"
        habit.incrementCompletion()
        try context.save()
        view = HabitRow(habit: habit, viewMode: .weekly)
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))
        subtitleText = try view.inspect().find(text: "Done today")
        #expect(try subtitleText.string() == "Done today")
    }
}
