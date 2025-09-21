//
//  PlaceholderView.swift
//  GekoWidgets
//
//  Created by Irenews on 9/21/25.
//

import WidgetKit
import SwiftUI

struct PlaceholderView: View {
    let habitName: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text(habitName.isEmpty ? "Select a Habit" : "Habit not found")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(habitName.isEmpty ? "Long press to configure" : "Check habit name in settings")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
