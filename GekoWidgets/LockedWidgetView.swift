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
        VStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)

            Text("Geko Plus")
                .font(.subheadline)
                .fontWeight(.medium)

            Text("Tap to upgrade")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("locked_widget_view")
    }
}
