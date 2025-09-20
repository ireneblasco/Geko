import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        HabitEditorForm(
            mode: .add(
                onConfirm: { name, emoji, color, dailyTarget in
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty, !emoji.isEmpty else { 
                        print("AddHabitView: Invalid input - name: '\(trimmed)', emoji: '\(emoji)'")
                        return false 
                    }
                    
                    let habit = Habit(name: trimmed, emoji: String(emoji.prefix(1)), color: color, dailyTarget: dailyTarget)
                    context.insert(habit)
                    print("AddHabitView: Created habit '\(habit.name)' with target \(habit.dailyTarget)")
                    
                    do {
                        try context.save()
                        print("AddHabitView: Successfully saved habit '\(habit.name)'")
                        return true
                    } catch {
                        print("AddHabitView: Failed to save new habit: \(error)")
                        // Remove the habit from context if save failed
                        context.delete(habit)
                        return false
                    }
                },
                onCancel: {
                    dismiss()
                }
            ),
            initialName: "",
            initialEmoji: "🔥",
            initialColor: .blue
        )
        .navigationBarBackButtonHidden(true)
    }
}
