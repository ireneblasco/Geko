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
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), habit: nil)
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
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration, habit: habit)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
    
    @MainActor
    private func loadHabit(named habitName: String) async -> Habit? {
        guard !habitName.isEmpty else { return nil }
        
        do {
            let container = SharedDataContainer.shared.modelContainer
            let context = container.mainContext
            
            let predicate = #Predicate<Habit> { habit in
                habit.name == habitName
            }
            let fetchDescriptor = FetchDescriptor<Habit>(predicate: predicate)
            
            let habits = try context.fetch(fetchDescriptor)
            return habits.first
        } catch {
            print("Failed to load habit from shared container: \(error)")
            return nil
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let habit: Habit?
}
