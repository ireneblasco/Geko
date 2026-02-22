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
            
            Text("Tap to create a habit")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Long press to choose a habit from the app")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
