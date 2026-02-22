//
//  ContentView.swift
//  Geko
//
//  Created by Irenews on 9/19/25.
//

import SwiftUI
import SwiftData
import WidgetKit
import GekoShared

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.name, order: .forward) private var habits: [Habit]
    #if DEBUG
    @ObservedObject private var feedbackManager = FeedbackManager.shared
    #endif

    @State private var showingAdd = false
    @State private var showingDebugSheet = false
    @State private var habitToEdit: Habit?
    @State private var searchText = ""
    
    // Persist last selected view mode across launches
    @AppStorage("lastSelectedViewMode") private var lastSelectedViewModeRaw: String = ViewMode.weekly.rawValue
    private var persistedViewMode: ViewMode {
        get { ViewMode(rawValue: lastSelectedViewModeRaw) ?? .weekly }
        set { lastSelectedViewModeRaw = newValue.rawValue }
    }
    @State private var viewMode: ViewMode = .weekly

    #if DEBUG
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
    #endif

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
        .onAppear {
            // Rehydrate selection on appear (defer to avoid mutating during render pass)
            DispatchQueue.main.async {
                viewMode = persistedViewMode
            }
            #if DEBUG
            // Provide model context for feedback trigger counting
            Task { @MainActor in
                feedbackManager.setModelContext(context)
            }
            #endif
        }
        .onChange(of: viewMode) { _, newValue in
            // Persist selection when it changes (write directly to @AppStorage backing value)
            lastSelectedViewModeRaw = newValue.rawValue
        }
    }
    
    @ViewBuilder
    private var mainNavigationView: some View {
        NavigationStack {
            mainContentView
                .navigationTitle("Habits")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            #if DEBUG
                            Button {
                                showingDebugSheet = true
                            } label: {
                                Label("Debug", systemImage: "ladybug")
                            }
                            .accessibilityIdentifier("debug_menu_button")
                            #endif
                            addHabitButton
                        }
                    }
                }
                .modifier(SearchableIfModifier(show: habits.count > 3, text: $searchText))
                .sheet(isPresented: $showingAdd) {
                    AddHabitView()
                        .presentationDetents([.medium, .large])
                }
                .sheet(item: $habitToEdit) { habit in
                    EditHabitView(habit: habit)
                        .presentationDetents([.medium, .large])
                }
                #if DEBUG
                .sheet(isPresented: Binding(
                    get: { feedbackManager.shouldShowFeedbackSheet },
                    set: { if !$0 { feedbackManager.markSheetPresented() } }
                )) {
                    FeedbackSheetView(onDismiss: { feedbackManager.markSheetPresented() })
                        .presentationDetents([.height(220), .medium])
                }
                .confirmationDialog("Debug", isPresented: $showingDebugSheet) {
                    Button("Build \(buildNumber)") { }
                    Button("Show Feedback") {
                        feedbackManager.showFeedbackSheetForDebug()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                #endif
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
        .accessibilityIdentifier("add_habit_button")
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
            print("📱 Deleting habit: '\(habit.name)'")
            
            // Sync deletion via Watch Connectivity before deleting locally
            SyncManager.shared.syncHabitDeletion(habitName: habit.name, habitId: habit.persistentModelID.hashValue)
            
            context.delete(habit)
        }
        
        do {
            try context.save()
            WidgetCenter.shared.reloadAllTimelines()
            print("📱 Successfully deleted \(habitsToDelete.count) habit(s)")
        } catch {
            print("📱 Failed to delete habits: \(error)")
        }
    }
}

// MARK: - Conditional Searchable
private struct SearchableIfModifier: ViewModifier {
    let show: Bool
    @Binding var text: String

    func body(content: Content) -> some View {
        if show {
            content.searchable(text: $text)
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
