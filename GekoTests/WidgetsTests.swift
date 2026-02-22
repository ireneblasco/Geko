//
//  WidgetsTests.swift
//  GekoTests
//
//  ViewInspector tests for Widgets feature (#9)
//  Tests shared components (YearHabitGrid) used by widget views.
//

import SwiftData
import SwiftUI
import Testing
import ViewInspector
import GekoShared

struct WidgetsTests {

    @Test @MainActor func yearHabitGrid_rendersWithHabit() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let calendar = Calendar(identifier: .gregorian)
        let view = YearHabitGrid(habit: habit, weekCount: 12, dotSize: 6)
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))
            .frame(width: 200, height: 100)

        let buttons = try view.inspect().findAll(ViewType.Button.self)
        #expect(buttons.count > 0)
    }

    @Test @MainActor func yearHabitGrid_tappingDotTogglesCompletion() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let calendar = Calendar(identifier: .gregorian)
        let refDate = Date()
        let grid = YearHabitGrid.habitGrid(for: refDate, weekCount: 12, calendar: calendar)

        var targetDay: Date?
        for dayOfWeek in 0..<7 {
            for weekIndex in 0..<grid[dayOfWeek].count {
                if let day = grid[dayOfWeek][weekIndex], calendar.isDateInToday(day) {
                    targetDay = day
                    break
                }
            }
            if targetDay != nil { break }
        }
        guard let day = targetDay else { return }

        #expect(!habit.isCompleted(on: day, calendar: calendar))

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        let dayString = formatter.string(from: day)
        let accessibilityLabel = "\(dayString): Not done"

        let view = YearHabitGrid(habit: habit, weekCount: 12, dotSize: 6)
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))
            .frame(width: 200, height: 100)

        try view.inspect().find(viewWithAccessibilityLabel: accessibilityLabel).button().tap()

        #expect(habit.isCompleted(on: day, calendar: calendar))
    }

    @Test @MainActor func yearHabitGrid_respectsWeekCount() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let calendar = Calendar(identifier: .gregorian)
        let grid = YearHabitGrid.habitGrid(for: Date(), weekCount: 12, calendar: calendar)

        #expect(grid[0].count == 12)
    }
}
