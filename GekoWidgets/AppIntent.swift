//
//  AppIntent.swift
//  GekoWidgets
//
//  Created by Irenews on 9/20/25.
//

import WidgetKit
import AppIntents
import SwiftData
import GekoShared

// Entity representing a habit for selection
struct HabitEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    static var defaultQuery = HabitQuery()
    
    var id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }
    
    var name: String
    var emoji: String
}

// Query to fetch available habits
struct HabitQuery: EntityQuery {
    func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        let habits = await loadAllHabits()
        return habits.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [HabitEntity] {
        return await loadAllHabits()
    }
    
    func defaultResult() async -> HabitEntity? {
        let habits = await loadAllHabits()
        return habits.first
    }
    
    private func loadAllHabits() async -> [HabitEntity] {
        // Try to load from shared SwiftData container first
        do {
            let container = SharedDataContainer.shared.modelContainer
            let context = await container.mainContext
            let fetchDescriptor = FetchDescriptor<Habit>()
            let habits = try context.fetch(fetchDescriptor)
            
            if !habits.isEmpty {
                return habits.map { habit in
                    HabitEntity(
                        id: habit.name, // Using name as ID for simplicity
                        name: habit.name,
                        emoji: habit.emoji
                    )
                }
            }
        } catch {
            print("Failed to load habits from shared SwiftData: \(error)")
        }
        
        // Fallback to sample habits if SwiftData is empty or fails
        return [
            HabitEntity(id: "Exercise", name: "Exercise", emoji: "💪"),
            HabitEntity(id: "Reading", name: "Reading", emoji: "📚"),
            HabitEntity(id: "Meditation", name: "Meditation", emoji: "🧘"),
            HabitEntity(id: "Water", name: "Drink Water", emoji: "💧"),
            HabitEntity(id: "Sleep", name: "Good Sleep", emoji: "😴")
        ]
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Select Habit" }
    static var description: IntentDescription { "Choose which habit to display in the widget." }

    @Parameter(title: "Habit", description: "The habit to track in this widget")
    var selectedHabit: HabitEntity?
    
    // Legacy property for backwards compatibility
    var habitName: String {
        return selectedHabit?.name ?? "Water"
    }
}

// Intent for completing a habit from the widget
struct CompleteHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Habit"
    static var description = IntentDescription("Mark habit as completed for today")
    
    @Parameter(title: "Habit Name")
    var habitName: String
    
    init() {}
    
    init(habitName: String) {
        self.habitName = habitName
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Get the shared model context
        let sharedModelContainer = SharedDataContainer.shared.modelContainer
        let context = sharedModelContainer.mainContext
        
        // Find the habit by name
        let predicate = #Predicate<Habit> { habit in
            habit.name == habitName
        }
        let fetchDescriptor = FetchDescriptor<Habit>(predicate: predicate)
        
        guard let habits = try? context.fetch(fetchDescriptor),
              let habit = habits.first else {
            return .result()
        }
        
        // Increment completion
        habit.incrementCompletion()
        
        // Save the context
        try? context.save()
        
        return .result()
    }
}

// Intent for toggling habit completion (reset if completed, increment if not)
struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit"
    static var description = IntentDescription("Toggle habit completion - reset if completed, increment if not")
    
    @Parameter(title: "Habit Name")
    var habitName: String
    
    init() {}
    
    init(habitName: String) {
        self.habitName = habitName
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Get the shared model context
        let sharedModelContainer = SharedDataContainer.shared.modelContainer
        let context = sharedModelContainer.mainContext
        
        // Find the habit by name
        let predicate = #Predicate<Habit> { habit in
            habit.name == habitName
        }
        let fetchDescriptor = FetchDescriptor<Habit>(predicate: predicate)
        
        guard let habits = try? context.fetch(fetchDescriptor),
              let habit = habits.first else {
            return .result()
        }
        
        // Check if habit is completed and toggle accordingly
        if habit.isCompleted() {
            // If already completed, reset to 0
            habit.resetCompletion()
        } else {
            // If not completed, increment by 1
            if habit.dailyTarget > 1 {
                habit.incrementCompletion()
            } else {
                habit.toggleCompleted()
            }
        }
        
        // Save the context
        try? context.save()
        
        return .result()
    }
}
