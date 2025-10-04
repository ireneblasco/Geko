//
//  HabitDetailView.swift
//  GekoWatch
//
//  Created by Geko Assistant
//

import SwiftUI
import SwiftData
import GekoShared

struct HabitDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var habit: Habit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header similar to SmallHabitWidgetView but larger for watch detail
            HStack(spacing: 12) {
                Button {
                    toggleCompletion()
                } label: {
                    ZStack {
                        // Progress ring background
                        Circle()
                            .stroke(habit.color.color.opacity(0.2), lineWidth: 3)
                            .frame(width: 40, height: 40)
                        
                        // Progress ring fill
                        Circle()
                            .trim(from: 0, to: habit.completionProgress())
                            .stroke(habit.color.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                        
                        // Emoji in center
                        Text(habit.emoji)
                            .font(.system(size: 22))
                    }
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text(completionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Year grid for watch detail - more weeks than widget but optimized for screen
            YearHabitGrid(
                habit: habit,
                weekCount: 16, // 4 months for watch detail view
                dotSize: 6,
                columnSpacing: 1.5,
                rowSpacing: 1.5
            )
        }
        .padding()
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Properties
    
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
    
    // MARK: - Actions
    
    private func toggleCompletion() {
        if habit.isCompleted() {
            habit.resetCompletion()
        } else {
            habit.incrementCompletion()
        }
        
        saveAndSync()
    }
    
    private func saveAndSync() {
        // Save to local context
        try? context.save()
        
        // Sync via Watch Connectivity
        let syncManager = SyncManager.shared
        syncManager.syncHabitCompletion(
            habitName: habit.name,
            date: Date(),
            isCompleted: habit.isCompleted(),
            completionCount: habit.completionCount()
        )
        
        print("⌚ HabitDetailView: Synced completion for '\(habit.name)': \(habit.completionCount())/\(habit.dailyTarget)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit(
            name: "Drink Water",
            emoji: "💧",
            color: .blue,
            dailyTarget: 8
        ))
    }
    .modelContainer(for: Habit.self, inMemory: true)
}
