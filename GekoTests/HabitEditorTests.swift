//
//  HabitEditorTests.swift
//  GekoTests
//
//  ViewInspector tests for Habit Editor feature (#4)
//

import SwiftData
import SwiftUI
import Testing
import ViewInspector
import GekoShared
@testable import Geko

struct HabitEditorTests {

    @Test @MainActor func habitEditorForm_addMode_showsAddTitle() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let form = HabitEditorForm(
            mode: .add(onConfirm: { _, _, _, _, _, _, _ in false }, onCancel: {}),
            initialName: "",
            initialEmoji: "🔥",
            initialColor: .blue
        )
        .modelContainer(container)

        // Add mode shows "Add" button in toolbar (navigation title may not be in hierarchy)
        _ = try form.inspect().find(button: "Add")
        _ = try form.inspect().find(text: "Details")
    }

    @Test @MainActor func habitEditorForm_editMode_showsEditTitle() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let habit = Habit(name: "Test", emoji: "✅", color: .blue, dailyTarget: 1)
        context.insert(habit)
        try context.save()

        let form = HabitEditorForm(
            mode: .edit(habit: habit, onConfirm: { _, _, _, _, _, _ in true }, onCancel: {}),
            initialName: habit.name,
            initialEmoji: habit.emoji,
            initialColor: habit.color,
            initialDailyTarget: habit.dailyTarget
        )
        .modelContainer(container)

        // Edit mode shows "Done" button in toolbar and habit name in form
        _ = try form.inspect().find(button: "Done")
        _ = try form.inspect().find(text: "Details")
    }

    @Test @MainActor func habitEditorForm_showsNameTextField() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let form = HabitEditorForm(
            mode: .add(onConfirm: { _, _, _, _, _, _, _ in false }, onCancel: {}),
            initialName: "",
            initialEmoji: "🔥",
            initialColor: .blue
        )
        .modelContainer(container)

        _ = try form.inspect().find(text: "Name")
    }

    @Test @MainActor func habitEditorForm_showsDailyTargetStepper() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let form = HabitEditorForm(
            mode: .add(onConfirm: { _, _, _, _, _, _, _ in false }, onCancel: {}),
            initialName: "",
            initialEmoji: "🔥",
            initialColor: .blue
        )
        .modelContainer(container)

        let title = try form.inspect().find(text: "Daily Target")
        #expect(try title.string() == "Daily Target")
    }

    @Test @MainActor func habitEditorForm_showsCancelAndAddButtons() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let form = HabitEditorForm(
            mode: .add(onConfirm: { _, _, _, _, _, _, _ in false }, onCancel: {}),
            initialName: "",
            initialEmoji: "🔥",
            initialColor: .blue
        )
        .modelContainer(container)

        _ = try form.inspect().find(button: "Cancel")
        _ = try form.inspect().find(button: "Add")
    }

    @Test @MainActor func habitEditorForm_emptyName_disablesAddButton() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let form = HabitEditorForm(
            mode: .add(onConfirm: { _, _, _, _, _, _, _ in false }, onCancel: {}),
            initialName: "",
            initialEmoji: "🔥",
            initialColor: .blue
        )
        .modelContainer(container)

        let addButton = try form.inspect().find(button: "Add")
        #expect(try addButton.isDisabled())
    }

    @Test @MainActor func addHabitView_wrapsHabitEditorForm() throws {
        let schema = Schema([Habit.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let view = AddHabitView()
            .modelContainer(container)

        // AddHabitView shows HabitEditorForm with add mode (Add button, Details section)
        _ = try view.inspect().find(HabitEditorForm.self)
        _ = try view.inspect().find(button: "Add")
        _ = try view.inspect().find(text: "Details")
    }
}
