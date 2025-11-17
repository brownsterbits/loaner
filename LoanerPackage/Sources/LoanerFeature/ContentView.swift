import SwiftUI
import SwiftData

@available(iOS 17.0, macOS 14.0, *)
public struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private var showingOnboarding: Binding<Bool> {
        Binding(
            get: { !hasSeenOnboarding },
            set: { _ in hasSeenOnboarding = true }
        )
    }

    public var body: some View {
        LoanListView()
            .sheet(isPresented: showingOnboarding) {
                OnboardingView()
                    .interactiveDismissDisabled()
            }
    }

    public init() {}
}
