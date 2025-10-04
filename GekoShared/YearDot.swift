//
//  YearDot.swift
//  Geko
//
//  Created by Irenews on 9/20/25.
//

import SwiftData
import SwiftUI

public struct YearDot: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.modelContext) private var context
    
    @Bindable var habit: Habit
    let day: Date
    let dotSize: CGFloat
    // Visual inset to create spacing inside the fixed cell size
    // Set to 1.0 for ~1pt gap (0.5 for subtler gap)
    private let visualInset: CGFloat = 1.0
    
    public init(habit: Habit, day: Date, dotSize: CGFloat) {
        self.habit = habit
        self.day = day
        self.dotSize = dotSize
    }
    
    public var body: some View {
        let isToday = calendar.isDateInToday(day)
        let completionProgress = habit.completionProgress(on: day, calendar: calendar)
        // Keep the cell frame at dotSize, but draw the fill slightly smaller
        let innerSize = max(0, dotSize - (visualInset))
        
        Button {
            let wasDone = habit.isCompleted(on: day, calendar: calendar)
            
            if wasDone {
                // If already completed, reset the day
                habit.resetCompletion(on: day, calendar: calendar)
            } else {
                // Use increment instead of toggle for multi-target habits
                if habit.dailyTarget > 1 {
                    habit.incrementCompletion(on: day, calendar: calendar)
                } else {
                    habit.toggleCompleted(on: day, calendar: calendar)
                }
                
                // Play sound if we just completed the habit (reached target)
                if habit.isCompleted(on: day, calendar: calendar) {
                    SoundFeedback.playCheck()
                }
            }
            
            try? context.save()
            
            // Sync habit completion via Watch Connectivity
            SyncManager.shared.syncHabitCompletion(
                habitName: habit.name,
                date: day,
                isCompleted: habit.isCompleted(on: day, calendar: calendar),
                completionCount: habit.completionCount(on: day, calendar: calendar)
            )
        } label: {
            ZStack {
                // Slightly smaller fill to create visual spacing
                RoundedRectangle(cornerRadius: 2)
                    .fill(completionProgress > 0 ?
                          habit.color.color.opacity(0.3 + (completionProgress * 0.7)) :
                          Color.secondary.opacity(0.3))
                    .frame(width: innerSize, height: innerSize)
            }
            .frame(width: dotSize, height: dotSize) // Preserve layout cell size
            .overlay {
                if isToday {
                    // Keep outline at full cell size for emphasis
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(habit.color.color.opacity(0.9), lineWidth: 1)
                        .frame(width: dotSize, height: dotSize)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        let dayString = formatter.string(from: day)
        
        let completionCount = habit.completionCount(on: day, calendar: calendar)
        let target = habit.dailyTarget
        
        if completionCount == 0 {
            return "\(dayString): Not done"
        } else if completionCount >= target {
            return "\(dayString): Complete (\(completionCount)/\(target))"
        } else {
            return "\(dayString): Partial (\(completionCount)/\(target))"
        }
    }
}
