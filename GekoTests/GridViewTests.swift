//
//  GridViewTests.swift
//  GekoTests
//
//  ViewInspector tests for Grid View feature (#3)
//

import SwiftData
import SwiftUI
import Testing
import ViewInspector
import GekoShared
@testable import Geko

struct GridViewTests {

    @Test @MainActor func viewModeToggleBar_showsThreeModes() throws {
        var selectedMode = ViewMode.weekly
        let binding = Binding(
            get: { selectedMode },
            set: { selectedMode = $0 }
        )

        let view = ViewModeToggleBar(selectedMode: binding)

        _ = try view.inspect().find(viewWithAccessibilityLabel: "Weekly")
        _ = try view.inspect().find(viewWithAccessibilityLabel: "Monthly")
        _ = try view.inspect().find(viewWithAccessibilityLabel: "Yearly")
    }

    @Test @MainActor func monthSummary_rendersWeekdayHeaders() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let calendar = Calendar(identifier: .gregorian)
        let refDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 21))!
        let view = MonthSummary(habit: habit, referenceDate: refDate)
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))

        let weekdayHeader = WeekSummary.weekDates(for: refDate, calendar: calendar)
        let firstSymbol = WeekSummary.shortWeekdaySymbol(for: weekdayHeader[0], calendar: calendar, locale: Locale(identifier: "en_US"))
        _ = try view.inspect().find(text: firstSymbol)
    }

    @Test @MainActor func monthSummary_rendersDayDots() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let calendar = Calendar(identifier: .gregorian)
        let refDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 21))!
        let view = MonthSummary(habit: habit, referenceDate: refDate)
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))

        let buttons = try view.inspect().findAll(ViewType.Button.self)
        #expect(buttons.count > 0)
    }

    @Test @MainActor func monthSummary_tappingDayDotTogglesCompletion() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let calendar = Calendar(identifier: .gregorian)
        let refDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 21))!
        let grid = MonthSummary.monthGrid(for: refDate, calendar: calendar)

        var targetDay: Date?
        for week in grid {
            for day in week {
                if let d = day, calendar.isDateInToday(d) {
                    targetDay = d
                    break
                }
            }
            if targetDay != nil { break }
        }
        guard let day = targetDay else { return }

        #expect(!habit.isCompleted(on: day, calendar: calendar))

        let view = MonthSummary(habit: habit, referenceDate: refDate)
            .modelContainer(container)
            .environment(\.calendar, calendar)
            .environment(\.locale, Locale(identifier: "en_US"))

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        let dayString = formatter.string(from: day)
        let accessibilityLabel = "\(dayString): Not done"
        try view.inspect().find(viewWithAccessibilityLabel: accessibilityLabel).button().tap()

        #expect(habit.isCompleted(on: day, calendar: calendar))
    }

    @Test @MainActor func yearSummary_containsScrollableYearGrid() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let refDate = Date()
        let view = YearSummary(habit: habit, referenceDate: refDate)
            .modelContainer(container)
            .environment(\.calendar, Calendar(identifier: .gregorian))
            .environment(\.locale, Locale(identifier: "en_US"))

        _ = try view.inspect().find(ScrollableYearHabitGrid.self)
    }

    @Test @MainActor func yearHabitGrid_displaysHabitData() throws {
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
}
