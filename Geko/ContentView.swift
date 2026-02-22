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
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    #if DEBUG
    @ObservedObject private var feedbackManager = FeedbackManager.shared
    #endif

    @State private var showingAdd = false
    @State private var showingPaywall = false
    @State private var showingDebugSheet = false
    #if DEBUG
    @State private var hideDebugButton = false
    #endif
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
            // Bootstrap sample habits and hide debug button when launched for screenshot capture
            if ProcessInfo.processInfo.arguments.contains("--bootstrapSampleHabitsForScreenshots") {
                bootstrapSampleHabits()
                hideDebugButton = true
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
                            if !hideDebugButton {
                                Button {
                                    showingDebugSheet = true
                                } label: {
                                    Label("Debug", systemImage: "ladybug")
                                }
                                .accessibilityIdentifier("debug_menu_button")
                            }
                            #endif
                            addHabitButton
                        }
                    }
                }
                .modifier(SearchableIfModifier(show: habits.count > 3, text: $searchText))
                .sheet(isPresented: $showingAdd) {
                    Group {
                        if !entitlementManager.isPlus && habits.count >= 3 {
                            PaywallView()
                        } else {
                            AddHabitView()
                        }
                    }
                    .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showingPaywall) {
                    PaywallView()
                        .presentationDetents([.medium, .large])
                }
                .onOpenURL { url in
                    if url.scheme == "geko" && url.host == "paywall" {
                        showingPaywall = true
                    }
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
                    Button("Show Paywall") {
                        showingPaywall = true
                    }
                    Button("Toggle Geko Plus (\(entitlementManager.isPlus ? "Plus" : "Free"))") {
                        entitlementManager.setPlus(!entitlementManager.isPlus)
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    Button("Bootstrap Sample Habits") {
                        bootstrapSampleHabits()
                    }
                    Button("Hide debug button") {
                        hideDebugButton = true
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

    #if DEBUG
    /// Deterministic sample data: ~70% of past days over `weeks`, matching widget provider preview.
    /// Returns (completedDays for simple habits, dailyCounts for multi-target with counts 4–8).
    private func sampleHabitData(weeks: Int = 26, calendar: Calendar) -> (Set<String>, [String: Int]) {
        var completed = Set<String>()
        var counts = [String: Int]()
        let today = calendar.startOfDay(for: Date())
        for weekOffset in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) else { continue }
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart), date <= today else { continue }
                let linearIndex = weekOffset * 7 + dayOffset
                if linearIndex % 10 < 7 {
                    let key = Habit.isoDay(for: date, in: calendar)
                    completed.insert(key)
                    counts[key] = 4 + (linearIndex % 5) // 4–8 for multi-target
                }
            }
        }
        return (completed, counts)
    }

    /// Same pattern as sampleHabitData but with offset for variety (e.g. Exercise vs Journal).
    private func sampleCompletedDaysOffset(weeks: Int, offset: Int, calendar: Calendar) -> Set<String> {
        var set = Set<String>()
        let today = calendar.startOfDay(for: Date())
        for weekOffset in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) else { continue }
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart), date <= today else { continue }
                let linearIndex = weekOffset * 7 + dayOffset + offset
                if linearIndex % 10 < 7 {
                    set.insert(Habit.isoDay(for: date, in: calendar))
                }
            }
        }
        return set
    }

    /// Creates 3 sample habits (Drink Water, Journal, Exercise) with varied completion profiles
    /// over ~26 weeks. Matches widget provider preview density for realistic debugging and screenshots.
    private func bootstrapSampleHabits() {
        let cal = Calendar.current
        let (completedDays, dailyCounts) = sampleHabitData(weeks: 26, calendar: cal)

        // Drink Water — multi-target, high-consistency (~70% of days with varying counts 4–8)
        let water = Habit(name: "Drink Water", emoji: "💧", color: .blue, dailyTarget: 8, remindersEnabled: false)
        water.dailyCompletionCounts = dailyCounts
        context.insert(water)

        // Journal — simple daily, ~70% of days completed
        let journal = Habit(name: "Journal", emoji: "📓", color: .indigo, dailyTarget: 1, remindersEnabled: false)
        journal.completedDays = completedDays
        context.insert(journal)

        // Exercise — simple daily, different pattern (~70% of days, offset for variety)
        let exercise = Habit(name: "Exercise", emoji: "💪", color: .green, dailyTarget: 1, remindersEnabled: false)
        exercise.completedDays = sampleCompletedDaysOffset(weeks: 26, offset: 3, calendar: cal)
        context.insert(exercise)

        do {
            try context.save()
            SyncManager.shared.syncHabitUpdate(water)
            SyncManager.shared.syncHabitUpdate(journal)
            SyncManager.shared.syncHabitUpdate(exercise)
            WidgetCenter.shared.reloadAllTimelines()
            print("📱 Bootstrapped 3 sample habits (Drink Water, Journal, Exercise)")
        } catch {
            print("📱 Failed to bootstrap sample habits: \(error)")
        }
    }
    #endif
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
