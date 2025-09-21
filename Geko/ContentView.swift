//
//  ContentView.swift
//  Geko
//
//  Created by Irenews on 9/19/25.
//

import SwiftUI
import SwiftData
import GekoShared

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.name, order: .forward) private var habits: [Habit]

    @State private var showingAdd = false
    @State private var habitToEdit: Habit?
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .weekly

    private var filteredHabits: [Habit] {
        guard !searchText.isEmpty else { return habits }
        return habits.filter { habit in
            let nameMatches = habit.name.localizedCaseInsensitiveContains(searchText)
            let emojiMatches = habit.emoji.contains(searchText)
            return nameMatches || emojiMatches
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            mainNavigationView
            
            // Floating pill toggle bar
            if !filteredHabits.isEmpty {
                ViewModeToggleBar(selectedMode: $viewMode)
            }
        }
    }
    
    @ViewBuilder
    private var mainNavigationView: some View {
        NavigationStack {
            mainContentView
                .navigationTitle("Habits")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        addHabitButton
                    }
                }
                .searchable(text: $searchText)
                .sheet(isPresented: $showingAdd) {
                    AddHabitView()
                        .presentationDetents([.medium, .large])
                }
                .sheet(item: $habitToEdit) { habit in
                    EditHabitView(habit: habit)
                        .presentationDetents([.medium, .large])
                }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        Group {
            if filteredHabits.isEmpty {
                emptyStateView
            } else {
                habitListView
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView("No Habits Yet",
                               systemImage: "checklist",
                               description: Text("Tap \"Add Habit\" to create your first habit."))
    }
    
    @ViewBuilder
    private var habitListView: some View {
        List {
            ForEach(filteredHabits) { habit in
                habitRowView(for: habit)
            }
            .onDelete(perform: delete)
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 60) // Space for floating toggle
        }
    }
    
    @ViewBuilder
    private func habitRowView(for habit: Habit) -> some View {
        HabitRow(habit: habit, viewMode: viewMode)
            .contentShape(Rectangle())
            .onTapGesture {
                habitToEdit = habit
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                swipeActionsView(for: habit)
            }
    }
    
    @ViewBuilder
    private func swipeActionsView(for habit: Habit) -> some View {
        Button("Edit") {
            habitToEdit = habit
        }
        .tint(.blue)

        Button(role: .destructive) {
            delete(habitsToDelete: [habit])
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private var addHabitButton: some View {
        Button {
            showingAdd = true
        } label: {
            Label("Add Habit", systemImage: "plus")
        }
    }
    
    private func delete(at offsets: IndexSet) {
        var toDelete: [Habit] = []
        for index in offsets {
            toDelete.append(filteredHabits[index])
        }
        delete(habitsToDelete: toDelete)
    }

    private func delete(habitsToDelete: [Habit]) {
        for habit in habitsToDelete {
            context.delete(habit)
        }
        try? context.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
