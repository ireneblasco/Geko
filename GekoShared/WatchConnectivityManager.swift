//
//  WatchConnectivityManager.swift
//  GekoShared
//
//  Created by Geko Assistant
//

import Foundation
import WatchConnectivity
import SwiftData
import Combine

public class WatchConnectivityManager: NSObject, ObservableObject {
    public static let shared = WatchConnectivityManager()
    
    @Published public var isConnected = false
    @Published public var isReachable = false
    
    private var modelContext: ModelContext?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    public func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Habit Syncing Methods
    
    public func syncHabitUpdate(_ habit: Habit) {
        guard WCSession.default.isReachable else { return }
        
        let habitData: [String: Any] = [
            "action": "habitUpdate",
            "habitId": habit.persistentModelID.hashValue, // Use hash as identifier
            "name": habit.name,
            "emoji": habit.emoji,
            "colorRawValue": habit.color.rawValue,
            "dailyTarget": habit.dailyTarget,
            "completedDays": Array(habit.completedDays),
            "dailyCompletionCounts": habit.dailyCompletionCounts,
            "remindersEnabled": habit.remindersEnabled,
            "reminderMessage": habit.reminderMessage ?? ""
        ]
        
        WCSession.default.sendMessage(habitData, replyHandler: nil) { error in
            print("Failed to send habit update: \(error.localizedDescription)")
        }
    }
    
    public func syncHabitCompletion(habitName: String, date: Date, isCompleted: Bool, completionCount: Int) {
        guard WCSession.default.isReachable else { return }
        
        let completionData: [String: Any] = [
            "action": "habitCompletion",
            "habitName": habitName,
            "date": ISO8601DateFormatter().string(from: date),
            "isCompleted": isCompleted,
            "completionCount": completionCount
        ]
        
        WCSession.default.sendMessage(completionData, replyHandler: nil) { error in
            print("Failed to send habit completion: \(error.localizedDescription)")
        }
    }
    
    public func syncHabitDeletion(habitName: String, habitId: Int) {
        guard WCSession.default.isReachable else { return }
        
        let deletionData: [String: Any] = [
            "action": "habitDeletion",
            "habitName": habitName,
            "habitId": habitId
        ]
        
        WCSession.default.sendMessage(deletionData, replyHandler: nil) { error in
            print("Failed to send habit deletion: \(error.localizedDescription)")
        }
    }
    
    public func requestFullSync() {
        guard WCSession.default.isReachable else { return }
        
        let syncRequest: [String: Any] = ["action": "requestFullSync"]
        
        WCSession.default.sendMessage(syncRequest, replyHandler: nil) { error in
            print("Failed to request full sync: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func handleHabitUpdate(_ message: [String: Any]) {
        guard let modelContext = self.modelContext,
              let name = message["name"] as? String,
              let emoji = message["emoji"] as? String,
              let colorRawValue = message["colorRawValue"] as? String,
              let dailyTarget = message["dailyTarget"] as? Int,
              let completedDays = message["completedDays"] as? [String],
              let dailyCompletionCounts = message["dailyCompletionCounts"] as? [String: Int] else {
            print("Invalid habit update message format")
            return
        }
        
        DispatchQueue.main.async {
            // Find existing habit or create new one
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { habit in
                    habit.name == name && habit.emoji == emoji
                }
            )
            
            do {
                let existingHabits = try modelContext.fetch(descriptor)
                let habit = existingHabits.first ?? Habit()
                
                // Update habit properties
                habit.name = name
                habit.emoji = emoji
                habit.color = HabitColor(rawValue: colorRawValue) ?? .blue
                habit.dailyTarget = dailyTarget
                habit.completedDays = Set(completedDays)
                habit.dailyCompletionCounts = dailyCompletionCounts
                habit.remindersEnabled = message["remindersEnabled"] as? Bool ?? false
                habit.reminderMessage = message["reminderMessage"] as? String
                
                if existingHabits.isEmpty {
                    modelContext.insert(habit)
                }
                
                try modelContext.save()
                print("Successfully synced habit update via Watch Connectivity")
                
            } catch {
                print("Failed to sync habit update: \(error)")
            }
        }
    }
    
    private func handleHabitCompletion(_ message: [String: Any]) {
        guard let modelContext = self.modelContext,
              let habitName = message["habitName"] as? String,
              let dateString = message["date"] as? String,
              let completionCount = message["completionCount"] as? Int else {
            print("Invalid habit completion message format")
            return
        }
        
        DispatchQueue.main.async {
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { habit in
                    habit.name == habitName
                }
            )
            
            do {
                let habits = try modelContext.fetch(descriptor)
                if let habit = habits.first,
                   let date = ISO8601DateFormatter().date(from: dateString) {
                    
                    let dayKey = Habit.isoDay(for: date)
                    
                    if habit.dailyTarget == 1 {
                        if completionCount > 0 {
                            habit.completedDays.insert(dayKey)
                        } else {
                            habit.completedDays.remove(dayKey)
                        }
                    } else {
                        habit.dailyCompletionCounts[dayKey] = completionCount
                    }
                    
                    try modelContext.save()
                    print("Successfully synced habit completion via Watch Connectivity")
                }
            } catch {
                print("Failed to sync habit completion: \(error)")
            }
        }
    }
    
    private func handleHabitDeletion(_ message: [String: Any]) {
        guard let modelContext = self.modelContext,
              let habitName = message["habitName"] as? String else {
            print("Invalid habit deletion message format")
            return
        }
        
        DispatchQueue.main.async {
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { habit in
                    habit.name == habitName
                }
            )
            
            do {
                let habits = try modelContext.fetch(descriptor)
                for habit in habits {
                    print("Deleting habit '\(habit.name)' via Watch Connectivity sync")
                    modelContext.delete(habit)
                }
                
                if !habits.isEmpty {
                    try modelContext.save()
                    print("Successfully synced habit deletion via Watch Connectivity")
                }
            } catch {
                print("Failed to sync habit deletion: \(error)")
            }
        }
    }
    
    private func sendAllHabits() {
        guard let modelContext = self.modelContext else { return }
        
        do {
            let habits = try modelContext.fetch(FetchDescriptor<Habit>())
            for habit in habits {
                syncHabitUpdate(habit)
            }
        } catch {
            print("Failed to fetch habits for full sync: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState != .notActivated
        }
        
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.description)")
        }
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        // Optionally, you can re-activate the session here if needed:
        // WCSession.default.activate()
    }
    #endif
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            
            // Notify SyncManager that connectivity status changed
            NotificationCenter.default.post(
                name: NSNotification.Name("WatchConnectivityStatusChanged"),
                object: nil
            )
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let action = message["action"] as? String else { return }
        
        switch action {
        case "habitUpdate":
            handleHabitUpdate(message)
        case "habitCompletion":
            handleHabitCompletion(message)
        case "habitDeletion":
            handleHabitDeletion(message)
        case "requestFullSync":
            sendAllHabits()
        default:
            print("Unknown action received: \(action)")
        }
    }
}

// MARK: - WCSessionActivationState Description

// We use @retroactive 
extension WCSessionActivationState: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .notActivated:
            return "Not Activated"
        case .inactive:
            return "Inactive"
        case .activated:
            return "Activated"
        @unknown default:
            return "Unknown"
        }
    }
}
