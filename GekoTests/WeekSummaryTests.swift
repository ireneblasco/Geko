//
//  WeekSummaryTests.swift
//  GekoTests
//

import SwiftData
import SwiftUI
import Testing
import ViewInspector
import GekoShared
@testable import Geko

struct WeekSummaryTests {

    @Test @MainActor func weekSummary_tappingDayButtonTogglesCompletion() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let calendar = Calendar(identifier: .gregorian)
        let weekDays = WeekSummary.sevenDaysEndingToday(for: Date(), calendar: calendar)
        let firstDay = weekDays[0]
        #expect(!habit.isCompleted(on: firstDay, calendar: calendar))

        let view = WeekSummary(habit: habit)
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))

        // Find and tap the first day button (find(button:) returns Button which has tap())
        let firstDaySymbol = WeekSummary.shortWeekdaySymbol(for: firstDay, calendar: calendar, locale: Locale(identifier: "en_US"))
        try view.inspect().find(button: firstDaySymbol).tap()

        #expect(habit.isCompleted(on: firstDay, calendar: calendar))
    }

    @Test @MainActor func weekSummary_tappingCompletedDayResetsCompletion() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)

        let calendar = Calendar(identifier: .gregorian)
        let weekDays = WeekSummary.sevenDaysEndingToday(for: Date(), calendar: calendar)
        let firstDay = weekDays[0]
        habit.toggleCompleted(on: firstDay, calendar: calendar)
        try context.save()

        #expect(habit.isCompleted(on: firstDay, calendar: calendar))

        let view = WeekSummary(habit: habit)
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))

        let firstDaySymbol = WeekSummary.shortWeekdaySymbol(for: firstDay, calendar: calendar, locale: Locale(identifier: "en_US"))
        try view.inspect().find(button: firstDaySymbol).tap()

        #expect(!habit.isCompleted(on: firstDay, calendar: calendar))
    }

}
