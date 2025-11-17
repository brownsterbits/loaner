import SwiftUI

/// Reusable help button that shows explanatory text in an alert
struct HelpButton: View {
    let title: String
    let message: String
    @State private var showingHelp = false

    var body: some View {
        Button {
            showingHelp = true
        } label: {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .alert(title, isPresented: $showingHelp) {
            Button("Got It", role: .cancel) {}
        } message: {
            Text(message)
        }
        .accessibilityLabel("Help: \(title)")
    }
}
