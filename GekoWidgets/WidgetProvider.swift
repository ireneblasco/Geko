//
//  WidgetProvider.swift
//  GekoWidgets
//
//  Created by Irenews on 9/21/25.
//

import WidgetKit
import SwiftUI
import SwiftData
import GekoShared

struct Provider: AppIntentTimelineProvider {
    @MainActor func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        // Try real habits from the shared store on this device (watch)
        let container = SharedDataContainer.shared.modelContainer
        let context = container.mainContext
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        
        let entities: [HabitEntity]
        if habits.isEmpty {
            // Fallback if nothing stored yet
            entities = [
                HabitEntity(id: "Water", name: "Drink Water", emoji: "💧"),
                HabitEntity(id: "Exercise", name: "Exercise", emoji: "💪"),
                HabitEntity(id: "Reading", name: "Reading", emoji: "📚"),
                HabitEntity(id: "Meditation", name: "Meditation", emoji: "🧘")
            ]
        } else {
            entities = habits.prefix(8).map {
                HabitEntity(id: $0.name, name: $0.name, emoji: $0.emoji)
            }
        }
        
        return entities.map { habit in
            var intent = ConfigurationAppIntent()
            intent.selectedHabit = habit
            return AppIntentRecommendation(intent: intent, description: habit.name)
        }
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), habit: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let habit = await loadHabit(named: configuration.habitName)
        return SimpleEntry(date: Date(), configuration: configuration, habit: habit)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let habit = await loadHabit(named: configuration.habitName)
        
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // Update every hour to keep the widget fresh
        for hourOffset in 0..<24 {
            guard let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate) else { continue }
            let entry = SimpleEntry(date: entryDate, configuration: configuration, habit: habit)
            entries.append(entry)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    @MainActor
    private func loadHabit(named habitName: String) async -> Habit? {
        guard !habitName.isEmpty else {
            return nil
        }
        
        do {
            let container = SharedDataContainer.shared.modelContainer
            let context = container.mainContext
            
            let predicate = #Predicate<Habit> { habit in
                habit.name == habitName
            }
            let fetchDescriptor = FetchDescriptor<Habit>(predicate: predicate)
            
            let habits = try context.fetch(fetchDescriptor)
            let result = habits.first
            return result
        } catch {
            return nil
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let habit: Habit?
}
