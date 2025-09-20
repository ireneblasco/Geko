//
//  ViewModeToggleBar.swift
//  Geko
//
//  Created by Irenews on 9/19/25.
//

import SwiftUI

struct ViewModeToggleBar: View {
    @Binding var selectedMode: ViewMode
    @Namespace private var toggleNamespace
    
    var body: some View {
        VStack {
            Spacer()
            toggleButtonsView
                .padding(4)
                .background(.regularMaterial, in: Capsule())
                .padding(.bottom, 20)
        }
    }
    
    @ViewBuilder
    private var toggleButtonsView: some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                toggleButton(for: mode)
            }
        }
    }
    
    @ViewBuilder
    private func toggleButton(for mode: ViewMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedMode = mode
            }
        } label: {
            Text(mode.rawValue)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selectedMode == mode ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    if selectedMode == mode {
                        Capsule()
                            .fill(.tint)
                            .matchedGeometryEffect(id: "toggle", in: toggleNamespace)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var viewMode = ViewMode.weekly
    
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        ViewModeToggleBar(selectedMode: $viewMode)
    }
}
