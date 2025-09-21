import SwiftUI

private extension ViewMode {
    var systemImageName: String {
        switch self {
        case .weekly:
            // Weekly: smaller grid
            return "circle.grid.2x1.right.filled"
        case .monthly:
            // Monthly: denser grid
            return "calendar"
        case .yearly:
            // Yearly: largest grid feel
            return "square.grid.3x3.bottomright.filled"
        }
    }
    
    var accessibilityLabel: String { rawValue }
}

public struct ViewModeToggleBar: View {
    @Binding var selectedMode: ViewMode
    @Namespace private var toggleNamespace
    
    public init(selectedMode: Binding<ViewMode>) {
        self._selectedMode = selectedMode
    }
    
    public var body: some View {
        // Top-left anchored pill
        HStack {
            toggleButtonsView
                .padding(4)
                .background(.regularMaterial, in: Capsule())
                .padding(.leading, 16)
                .padding(.top, 8)
            Spacer()
        }
        .ignoresSafeArea(.keyboard) // keep position when keyboard appears
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
            Image(systemName: mode.systemImageName)
                .font(.system(size: 14, weight: .semibold))
                .symbolRenderingMode(.monochrome)
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
                .accessibilityLabel(mode.accessibilityLabel)
        }
        .buttonStyle(.plain)
    }
}
