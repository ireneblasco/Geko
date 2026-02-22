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

// MARK: - Sample Habit for Widget Gallery

private enum SampleHabit {
    /// Creates a non-persisted habit with realistic completion data for widget gallery preview.
    static func create() -> Habit {
        let habit = Habit(name: "Drink Water", emoji: "💧", color: .blue)
        habit.completedDays = sampleCompletedDays(weeks: 26)
        return habit
    }

    /// Deterministic pattern: ~70% of past days marked complete for a realistic year grid.
    private static func sampleCompletedDays(weeks: Int = 26) -> Set<String> {
        var set = Set<String>()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        for weekOffset in 0..<weeks {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: today) else { continue }
            for dayOffset in 0..<7 {
                guard let date = cal.date(byAdding: .day, value: dayOffset, to: weekStart), date <= today else { continue }
                let linearIndex = weekOffset * 7 + dayOffset
                if linearIndex % 10 < 7 {
                    set.insert(Habit.isoDay(for: date, in: cal))
                }
            }
        }
        return set
    }
}

@MainActor
struct Provider: AppIntentTimelineProvider {
    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
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
    
    private var isPlus: Bool {
        UserDefaults(suiteName: SharedDataContainer.appGroupIdentifier)?
            .bool(forKey: isPlusUserDefaultsKey) ?? false
    }

    func placeholder(in context: Context) -> SimpleEntry {
        if !isPlus {
            var config = ConfigurationAppIntent()
            config.selectedHabit = HabitEntity(id: "", name: "", emoji: "")
            return SimpleEntry(date: Date(), configuration: config, habit: nil, isLocked: true)
        }
        let habit = loadPreviewHabit() ?? SampleHabit.create()
        var config = ConfigurationAppIntent()
        config.selectedHabit = HabitEntity(id: habit.name, name: habit.name, emoji: habit.emoji)
        return SimpleEntry(date: Date(), configuration: config, habit: habit)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        if !isPlus {
            return SimpleEntry(date: Date(), configuration: configuration, habit: nil, isLocked: true)
        }
        let habit = await loadHabit(named: configuration.habitName)
        let displayHabit: Habit? = (context.isPreview || habit == nil) ? (loadPreviewHabit() ?? SampleHabit.create()) : habit
        return SimpleEntry(date: Date(), configuration: configuration, habit: displayHabit)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        if !isPlus {
            let entry = SimpleEntry(date: Date(), configuration: configuration, habit: nil, isLocked: true)
            return Timeline(entries: [entry], policy: .atEnd)
        }

        let habit = await loadHabit(named: configuration.habitName)

        var entries: [SimpleEntry] = []
        let currentDate = Date()

        for hourOffset in 0..<24 {
            guard let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate) else { continue }
            let entry = SimpleEntry(date: entryDate, configuration: configuration, habit: habit)
            entries.append(entry)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
    
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

    /// Returns the first habit with completion history for preview, or nil if none.
    private func loadPreviewHabit() -> Habit? {
        guard let habits = try? SharedDataContainer.shared.modelContainer.mainContext.fetch(FetchDescriptor<Habit>()) else {
            return nil
        }
        return habits.first { habit in
            !habit.completedDays.isEmpty || !habit.dailyCompletionCounts.isEmpty
        } ?? habits.first
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let habit: Habit?
    let isLocked: Bool

    init(date: Date, configuration: ConfigurationAppIntent, habit: Habit?, isLocked: Bool = false) {
        self.date = date
        self.configuration = configuration
        self.habit = habit
        self.isLocked = isLocked
    }
}
