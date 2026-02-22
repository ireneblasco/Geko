//
//  HabitTests.swift
//  GekoTests
//

import Foundation
import SwiftData
import Testing
import GekoShared

struct HabitTests {

    @Test func habitCreation_setsPropertiesCorrectly() throws {
        let habit = Habit(name: "Meditate", emoji: "🧘", color: .purple, dailyTarget: 1)
        #expect(habit.name == "Meditate")
        #expect(habit.emoji == "🧘")
        #expect(habit.color == .purple)
        #expect(habit.dailyTarget == 1)
        #expect(habit.remindersEnabled == false)
        #expect(habit.completedDays.isEmpty)
    }

    @Test func habitCreation_dailyTargetClampedToMinimumOne() throws {
        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 0)
        #expect(habit.dailyTarget == 1)
    }

    @Test @MainActor func habitCreation_canInsertAndSave() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Read", emoji: "📚", color: .indigo, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let descriptor = FetchDescriptor<Habit>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched[0].name == "Read")
        #expect(fetched[0].emoji == "📚")
    }

    @Test func habitCreation_storesEmojiAsProvided() throws {
        let habit = Habit(name: "Exercise", emoji: "🏃", color: .green, dailyTarget: 1)
        #expect(habit.emoji == "🏃")
    }

    @Test func habitCreation_isoDayFormat() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: 2025, month: 2, day: 21))!
        let iso = Habit.isoDay(for: date, in: calendar)
        #expect(iso == "2025-02-21")
    }

}
