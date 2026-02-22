import SwiftUI
import SwiftData
import UserNotifications
import GekoShared

struct HabitEditorForm: View {
    enum Mode {
        case add(onConfirm: (_ name: String, _ emoji: String, _ color: HabitColor, _ dailyTarget: Int, _ remindersEnabled: Bool, _ reminderTimes: [Date], _ reminderMessage: String?) -> Bool, onCancel: () -> Void)
        case edit(habit: Habit, onConfirm: (_ name: String, _ emoji: String, _ dailyTarget: Int, _ remindersEnabled: Bool, _ reminderTimes: [Date], _ reminderMessage: String?) -> Bool, onCancel: () -> Void)

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
    @State private var remindersEnabled: Bool
    @State private var reminderTimes: [Date]
    @State private var reminderMessage: String
    @State private var isPickingEmoji = false
    @State private var isRequestingNotificationPermission = false

    init(mode: Mode, initialName: String, initialEmoji: String, initialColor: HabitColor, initialDailyTarget: Int = 1, initialRemindersEnabled: Bool = false, initialReminderTimes: [Date] = [], initialReminderMessage: String = "") {
        self.mode = mode
        _name = State(initialValue: initialName)
        _emoji = State(initialValue: initialEmoji)
        _color = State(initialValue: initialColor)
        _dailyTarget = State(initialValue: max(1, initialDailyTarget))
        _remindersEnabled = State(initialValue: initialRemindersEnabled)
        _reminderTimes = State(initialValue: initialReminderTimes)
        _reminderMessage = State(initialValue: initialReminderMessage)
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
                
                Section("Reminders") {
                    Toggle("Enable Reminders", isOn: $remindersEnabled)
                        .onChange(of: remindersEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    await requestNotificationPermissionIfNeeded()
                                }
                            }
                        }
                    
                    if remindersEnabled {
                        HStack {
                            Text("Reminder Time")
                            Spacer()
                            DatePicker("", selection: .init(
                                get: { 
                                    reminderTimes.first ?? {
                                        let calendar = Calendar.current
                                        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
                                    }()
                                },
                                set: { newTime in
                                    if reminderTimes.isEmpty {
                                        reminderTimes.append(newTime)
                                    } else {
                                        reminderTimes[0] = newTime
                                    }
                                }
                            ), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        }
                        .disabled(isRequestingNotificationPermission)
                        
                        TextField("Custom message (optional)", text: $reminderMessage, axis: .vertical)
                            .lineLimit(2...4)
                            .disabled(isRequestingNotificationPermission)
                        
                        if isRequestingNotificationPermission {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Requesting notification permission...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
                    emoji = picked
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

    private func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        
        // Check current authorization status
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .notDetermined:
            // Request permission
            isRequestingNotificationPermission = true
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    isRequestingNotificationPermission = false
                    if !granted {
                        // If permission denied, turn off reminders
                        remindersEnabled = false
                    }
                }
            } catch {
                await MainActor.run {
                    isRequestingNotificationPermission = false
                    remindersEnabled = false
                }
                print("Failed to request notification permission: \(error)")
            }
        case .denied:
            // Permission was previously denied, turn off reminders
            await MainActor.run {
                remindersEnabled = false
            }
            // Optionally show an alert here explaining how to enable notifications in Settings
        case .authorized, .provisional, .ephemeral:
            // Permission already granted, no action needed
            break
        @unknown default:
            break
        }
    }

    private func confirm() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !emoji.isEmpty else { return }

        switch mode {
        case .add(let onConfirm, _):
            let finalReminderMessage = reminderMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : reminderMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            if onConfirm(trimmed, emoji, color, dailyTarget, remindersEnabled, reminderTimes, finalReminderMessage) {
                dismiss()
            }

        case .edit(habit: let habit, onConfirm: let onConfirm, onCancel: _):
            // Store original values in case we need to revert
            let originalName = habit.name
            let originalEmoji = habit.emoji
            let originalColor = habit.color
            let originalDailyTarget = habit.dailyTarget
            let originalRemindersEnabled = habit.remindersEnabled
            let originalReminderTimes = habit.reminderTimes
            let originalReminderMessage = habit.reminderMessage
            
            print("HabitEditorForm: Editing habit '\(originalName)' -> '\(trimmed)'")
            
            // Update habit properties
            let finalReminderMessage = reminderMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : reminderMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            habit.name = trimmed
            habit.emoji = emoji
            habit.color = color
            habit.dailyTarget = dailyTarget
            habit.remindersEnabled = remindersEnabled
            habit.reminderTimes = reminderTimes
            habit.reminderMessage = finalReminderMessage
            
            // Try to save the changes
            do {
                try context.save()
                print("HabitEditorForm: Successfully saved changes to habit '\(habit.name)'")
                
                // Sync the updated habit via Watch Connectivity
                SyncManager.shared.syncHabitUpdate(habit)
                
                // Update reminders asynchronously
                Task {
                    await habit.updateReminders()
                }
                
                // Call the confirmation callback
                if onConfirm(trimmed, emoji, dailyTarget, remindersEnabled, reminderTimes, finalReminderMessage) {
                    dismiss()
                } else {
                    // Revert changes if confirmation fails
                    habit.name = originalName
                    habit.emoji = originalEmoji
                    habit.color = originalColor
                    habit.dailyTarget = originalDailyTarget
                    habit.remindersEnabled = originalRemindersEnabled
                    habit.reminderTimes = originalReminderTimes
                    habit.reminderMessage = originalReminderMessage
                    try? context.save()
                    print("HabitEditorForm: Reverted changes due to confirmation failure")
                }
            } catch {
                // Revert changes if save fails
                habit.name = originalName
                habit.emoji = originalEmoji
                habit.color = originalColor
                habit.dailyTarget = originalDailyTarget
                habit.remindersEnabled = originalRemindersEnabled
                habit.reminderTimes = originalReminderTimes
                habit.reminderMessage = originalReminderMessage
                
                print("HabitEditorForm: Failed to save habit changes: \(error)")
                // You might want to show an alert to the user here
            }
        }
    }
}
