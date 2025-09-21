//
//  SmallHabitWidgetView.swift
//  GekoWidgets
//
//  Created by Irenews on 9/21/25.
//

import WidgetKit
import SwiftUI
import GekoShared

struct SmallHabitWidgetView: View {
    let habit: Habit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Small widget layout - emoji with completion circle is the button
            HStack(spacing: 0) {
                Button(intent: ToggleHabitIntent(habitName: habit.name)) {
                    ZStack {
                        // Progress ring background
                        Circle()
                            .stroke(habit.color.color.opacity(0.2), lineWidth: 2.5)
                            .frame(width: 32, height: 32)
                        
                        // Progress ring fill
                        Circle()
                            .trim(from: 0, to: habit.completionProgress())
                            .stroke(habit.color.color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))
                        
                        // Emoji in center
                        Text(habit.emoji)
                            .font(.system(size: 18))
                    }
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(habit.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(completionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }.padding(.leading, 8)
                
                Spacer()
            }.padding(.bottom, 12)
            
            // Year grid for small widget
            YearHabitGrid(
                habit: habit,
                weekCount: 12, // 12 weeks for small widget
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
