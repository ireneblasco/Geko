//
//  AppIntents.swift
//  GekoShared
//
//  Shared App Intents for Shortcuts, widgets, and external integrations.
//

import AppIntents
import SwiftData
import WidgetKit

// MARK: - Habit Entity

public struct HabitEntity: AppEntity {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Habit")
    public static var defaultQuery = HabitQuery()

    public var id: String
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(emoji)")
    }

    public var name: String
    public var emoji: String

    public init(id: String, name: String, emoji: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
    }
}

// MARK: - Habit Query

public struct HabitQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        let habits = await loadAllHabits()
        return habits.filter { identifiers.contains($0.id) }
    }

    public func suggestedEntities() async throws -> [HabitEntity] {
        return await loadAllHabits()
    }

    public func defaultResult() async -> HabitEntity? {
        let habits = await loadAllHabits()
        return habits.first
    }

    private func loadAllHabits() async -> [HabitEntity] {
        do {
            let container = SharedDataContainer.shared.modelContainer
            let context = await container.mainContext
            let fetchDescriptor = FetchDescriptor<Habit>()
            let habits = try context.fetch(fetchDescriptor)

            if !habits.isEmpty {
                return habits.map { habit in
                    HabitEntity(
                        id: habit.name,
                        name: habit.name,
                        emoji: habit.emoji
                    )
                }
            }
        } catch {
            print("Failed to load habits from shared SwiftData: \(error)")
        }

        return [
            HabitEntity(id: "Exercise", name: "Exercise", emoji: "💪"),
            HabitEntity(id: "Reading", name: "Reading", emoji: "📚"),
            HabitEntity(id: "Meditation", name: "Meditation", emoji: "🧘"),
            HabitEntity(id: "Water", name: "Drink Water", emoji: "💧"),
            HabitEntity(id: "Sleep", name: "Good Sleep", emoji: "😴")
        ]
    }
}

// MARK: - Complete Habit Intent

public struct CompleteHabitIntent: AppIntent {
    public static var title: LocalizedStringResource = "Complete Habit"
    public static var description = IntentDescription("Mark habit as completed for today")

    @Parameter(title: "Habit")
    public var habit: HabitEntity?

    public init() {}

    public init(habit: HabitEntity?) {
        self.habit = habit
    }

    public init(habitName: String) {
        self.habit = HabitEntity(id: habitName, name: habitName, emoji: "✅")
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let habitName = habit?.name ?? ""
        guard !habitName.isEmpty else {
            return .result(value: "No habit selected")
        }

        let sharedModelContainer = SharedDataContainer.shared.modelContainer
        let context = sharedModelContainer.mainContext

        let predicate = #Predicate<Habit> { h in h.name == habitName }
        let fetchDescriptor = FetchDescriptor<Habit>(predicate: predicate)

        guard let habits = try? context.fetch(fetchDescriptor),
              let habitModel = habits.first else {
            return .result(value: "Habit '\(habitName)' not found")
        }

        habitModel.incrementCompletion()
        try? context.save()

        SyncManager.shared.syncHabitCompletion(
            habitName: habitModel.name,
            date: Date(),
            isCompleted: habitModel.isCompleted(),
            completionCount: habitModel.completionCount()
        )
        WidgetCenter.shared.reloadAllTimelines()

        return .result(value: "\(habitName) completed")
    }
}

// MARK: - Toggle Habit Intent

public struct ToggleHabitIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Habit"
    public static var description = IntentDescription("Toggle habit completion - reset if completed, increment if not")

    @Parameter(title: "Habit")
    public var habit: HabitEntity?

    public init() {}

    public init(habit: HabitEntity?) {
        self.habit = habit
    }

    public init(habitName: String) {
        self.habit = HabitEntity(id: habitName, name: habitName, emoji: "✅")
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let habitName = habit?.name ?? ""
        guard !habitName.isEmpty else {
            return .result(value: "No habit selected")
        }

        let sharedModelContainer = SharedDataContainer.shared.modelContainer
        let context = sharedModelContainer.mainContext

        let predicate = #Predicate<Habit> { h in h.name == habitName }
        let fetchDescriptor = FetchDescriptor<Habit>(predicate: predicate)

        guard let habits = try? context.fetch(fetchDescriptor),
              let habitModel = habits.first else {
            return .result(value: "Habit '\(habitName)' not found")
        }

        if habitModel.isCompleted() {
            habitModel.resetCompletion()
        } else {
            if habitModel.dailyTarget > 1 {
                habitModel.incrementCompletion()
            } else {
                habitModel.toggleCompleted()
            }
        }

        try? context.save()

        SyncManager.shared.syncHabitCompletion(
            habitName: habitModel.name,
            date: Date(),
            isCompleted: habitModel.isCompleted(),
            completionCount: habitModel.completionCount()
        )
        WidgetCenter.shared.reloadAllTimelines()

        return .result(value: "\(habitName) toggled")
    }
}
