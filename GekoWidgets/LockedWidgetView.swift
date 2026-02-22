//
//  LockedWidgetView.swift
//  GekoWidgets
//
//  Shown when user is not Plus. Tapping opens the app to upgrade.
//

import WidgetKit
import SwiftUI

struct LockedWidgetView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("Unlock Geko Plus")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Tap to upgrade and add widgets")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("locked_widget_view")
    }
}
