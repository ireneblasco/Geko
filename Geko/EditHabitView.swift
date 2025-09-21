import SwiftUI
import SwiftData
import GekoShared

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var habit: Habit

    var body: some View {
        HabitEditorForm(
            mode: .edit(
                habit: habit,
                onConfirm: { _, _, _, _, _, _ in
                    // Habit is already mutated in the form before this closure.
                    // Return true to allow dismiss.
                    true
                },
                onCancel: {
                    dismiss()
                }
            ),
            initialName: habit.name,
            initialEmoji: habit.emoji,
            initialColor: habit.color,
            initialDailyTarget: habit.dailyTarget,
            initialRemindersEnabled: habit.remindersEnabled,
            initialReminderTimes: habit.reminderTimes,
            initialReminderMessage: habit.reminderMessage ?? ""
        )
        .navigationBarBackButtonHidden(true)
    }
}
