import Foundation
import SwiftData

@Model
final class Habit {
    var name: String
    var emoji: String
    var color: HabitColor
    
    // Daily target: how many times the user needs to complete this habit per day
    var dailyTarget: Int
    
    // Store completed days as ISO-8601 date-only strings: "YYYY-MM-DD"
    // For simple habits (dailyTarget = 1), this remains the same
    var completedDays: Set<String>
    
    // Store completion counts per day for habits with dailyTarget > 1
    // Key: ISO-8601 date string, Value: number of completions that day
    var dailyCompletionCounts: [String: Int]
    
    init(name: String, emoji: String, color: HabitColor, dailyTarget: Int = 1) {
        self.name = name
        self.emoji = emoji
        self.color = color
        self.dailyTarget = max(1, dailyTarget) // Ensure at least 1
        self.completedDays = []
        self.dailyCompletionCounts = [:]
    }
}

extension Habit {
    static func isoDay(for date: Date = .now, in calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let year = comps.year ?? 0
        let month = comps.month ?? 0
        let day = comps.day ?? 0
        // zero-pad month/day
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
    
    /// Returns the completion count for a specific date
    func completionCount(on date: Date = .now, calendar: Calendar = .current) -> Int {
        let key = Self.isoDay(for: date, in: calendar)
        
        // For dailyTarget = 1, check completedDays for backward compatibility
        if dailyTarget == 1 {
            return completedDays.contains(key) ? 1 : 0
        }
        
        // For dailyTarget > 1, check dailyCompletionCounts
        return dailyCompletionCounts[key] ?? 0
    }
    
    /// Returns the completion progress as a value between 0.0 and 1.0
    func completionProgress(on date: Date = .now, calendar: Calendar = .current) -> Double {
        let count = completionCount(on: date, calendar: calendar)
        return min(1.0, Double(count) / Double(dailyTarget))
    }
    
    /// Returns whether the habit is fully completed for the day
    func isCompleted(on date: Date = .now, calendar: Calendar = .current) -> Bool {
        completionCount(on: date, calendar: calendar) >= dailyTarget
    }
    
    /// Returns whether the habit is partially completed (but not fully completed)
    func isPartiallyCompleted(on date: Date = .now, calendar: Calendar = .current) -> Bool {
        let count = completionCount(on: date, calendar: calendar)
        return count > 0 && count < dailyTarget
    }
    
    /// Increments the completion count for a specific date
    func incrementCompletion(on date: Date = .now, calendar: Calendar = .current) {
        let key = Self.isoDay(for: date, in: calendar)
        let currentCount = completionCount(on: date, calendar: calendar)
        
        if currentCount < dailyTarget {
            if dailyTarget == 1 {
                // For simple habits, use completedDays for backward compatibility
                completedDays.insert(key)
            } else {
                // For multi-target habits, use dailyCompletionCounts
                dailyCompletionCounts[key] = currentCount + 1
            }
        }
    }
    
    /// Legacy method for backward compatibility - toggles between 0 and full completion
    func toggleCompleted(on date: Date = .now, calendar: Calendar = .current) {
        let key = Self.isoDay(for: date, in: calendar)
        
        if dailyTarget == 1 {
            // For simple habits, toggle the old way
            if completedDays.contains(key) {
                completedDays.remove(key)
            } else {
                completedDays.insert(key)
            }
        } else {
            // For multi-target habits, toggle between 0 and full completion
            let currentCount = completionCount(on: date, calendar: calendar)
            if currentCount >= dailyTarget {
                dailyCompletionCounts[key] = 0
            } else {
                dailyCompletionCounts[key] = dailyTarget
            }
        }
    }
    
    /// Resets completion count for a specific date to 0
    func resetCompletion(on date: Date = .now, calendar: Calendar = .current) {
        let key = Self.isoDay(for: date, in: calendar)
        
        if dailyTarget == 1 {
            completedDays.remove(key)
        } else {
            dailyCompletionCounts.removeValue(forKey: key)
        }
    }
}
