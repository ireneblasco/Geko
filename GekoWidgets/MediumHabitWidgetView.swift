//
//  MediumHabitWidgetView.swift
//  GekoWidgets
//
//  Created by Irenews on 9/21/25.
//

import WidgetKit
import SwiftUI
import GekoShared

struct MediumHabitWidgetView: View {
    let habit: Habit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Medium widget layout - separate emoji and completion button
            HStack(spacing: 0) {
                // Habit emoji and name
                HStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(habit.color.color.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Text(habit.emoji)
                            .font(.system(size: 18))
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(habit.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text(completionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }.padding(.leading, 8)
                }
                
                Spacer()
                
                // Completion button
                Button(intent: ToggleHabitIntent(habitName: habit.name)) {
                    ZStack {
                        // Progress ring background
                        Circle()
                            .stroke(habit.color.color.opacity(0.2), lineWidth: 2.5)
                            .frame(width: 28, height: 28)
                        
                        // Progress ring fill
                        Circle()
                            .trim(from: 0, to: habit.completionProgress())
                            .stroke(habit.color.color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))
                        
                        // Center icon
                        Image(systemName: habit.isCompleted() ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(habit.isCompleted() ? habit.color.color : .secondary)
                    }
                }
                .buttonStyle(.plain)
            }.padding(.bottom, 12)
            
            // Year grid for medium widget
            YearHabitGrid(
                habit: habit,
                weekCount: 26, // 26 weeks for medium widget
                dotSize: 4,
                columnSpacing: 1,
                rowSpacing: 1
            )
        }
    }
    
    private var completionText: String {
        let count = habit.completionCount()
        let target = habit.dailyTarget
        
        if habit.isCompleted() {
            return "Complete (\(count)/\(target))"
        } else if count > 0 {
            return "Progress (\(count)/\(target))"
        } else {
            return "Not done today"
        }
    }
}
