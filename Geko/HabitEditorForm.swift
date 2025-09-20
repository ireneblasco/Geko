import SwiftUI
import SwiftData

struct HabitEditorForm: View {
    enum Mode {
        case add(onConfirm: (_ name: String, _ emoji: String, _ color: HabitColor, _ dailyTarget: Int) -> Bool, onCancel: () -> Void)
        case edit(habit: Habit, onConfirm: (_ name: String, _ emoji: String, _ dailyTarget: Int) -> Bool, onCancel: () -> Void)

        var isAdd: Bool {
            if case .add = self { return true }
            return false
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let mode: Mode

    @State private var name: String
    @State private var emoji: String
    @State private var color: HabitColor
    @State private var dailyTarget: Int
    @State private var isPickingEmoji = false

    init(mode: Mode, initialName: String, initialEmoji: String, initialColor: HabitColor, initialDailyTarget: Int = 1) {
        self.mode = mode
        _name = State(initialValue: initialName)
        _emoji = State(initialValue: initialEmoji)
        _color = State(initialValue: initialColor)
        _dailyTarget = State(initialValue: max(1, initialDailyTarget))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    HStack(spacing: 12) {
                        Button {
                            isPickingEmoji = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(colorDisplay.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Text(emoji)
                                    .font(.system(size: 20))
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Change emoji")
                        
                        TextField("Name", text: $name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    
                    if showsColorPicker {
                        ColorPickerGrid(selection: $color)
                    }
                }
                
                Section("Advanced") {
                    HStack {
                        Text("Daily Target")
                        Spacer()
                        Stepper(
                            value: $dailyTarget,
                            in: 1...20,
                            step: 1
                        ) {
                            Text("\(dailyTarget) time\(dailyTarget == 1 ? "" : "s")")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Daily target: \(dailyTarget) time\(dailyTarget == 1 ? "" : "s")")
                    
                    if dailyTarget > 1 {
                        Text("You'll need to tap \(dailyTarget) times to mark this habit as complete for the day.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(mode.isAdd ? "Add Habit" : "Edit Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        switch mode {
                        case .add(_, let onCancel):
                            onCancel()
                        case .edit(habit: _, onConfirm: _, onCancel: let onCancel):
                            onCancel()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.isAdd ? "Add" : "Done") {
                        confirm()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $isPickingEmoji) {
                EmojiCatalogPicker { picked in
                    emoji = String(picked.prefix(1))
                    isPickingEmoji = false
                } onCancel: {
                    isPickingEmoji = false
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Private Properties

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !emoji.isEmpty
    }

    private var showsColorPicker: Bool {
        // Always show color picker for both add and edit modes
        true
    }

    private var colorDisplay: Color {
        // Always show the currently selected color
        color.color
    }

    // MARK: - Private Methods

    private func confirm() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !emoji.isEmpty else { return }

        switch mode {
        case .add(let onConfirm, _):
            if onConfirm(trimmed, emoji, color, dailyTarget) {
                dismiss()
            }

        case .edit(habit: let habit, onConfirm: let onConfirm, onCancel: _):
            // Store original values in case we need to revert
            let originalName = habit.name
            let originalEmoji = habit.emoji
            let originalColor = habit.color
            let originalDailyTarget = habit.dailyTarget
            
            print("HabitEditorForm: Editing habit '\(originalName)' -> '\(trimmed)'")
            
            // Update habit properties
            habit.name = trimmed
            habit.emoji = String(emoji.prefix(1))
            habit.color = color
            habit.dailyTarget = dailyTarget
            
            // Try to save the changes
            do {
                try context.save()
                print("HabitEditorForm: Successfully saved changes to habit '\(habit.name)'")
                
                // Call the confirmation callback
                if onConfirm(trimmed, emoji, dailyTarget) {
                    dismiss()
                } else {
                    // Revert changes if confirmation fails
                    habit.name = originalName
                    habit.emoji = originalEmoji
                    habit.color = originalColor
                    habit.dailyTarget = originalDailyTarget
                    try? context.save()
                    print("HabitEditorForm: Reverted changes due to confirmation failure")
                }
            } catch {
                // Revert changes if save fails
                habit.name = originalName
                habit.emoji = originalEmoji
                habit.color = originalColor
                habit.dailyTarget = originalDailyTarget
                
                print("HabitEditorForm: Failed to save habit changes: \(error)")
                // You might want to show an alert to the user here
            }
        }
    }
}
