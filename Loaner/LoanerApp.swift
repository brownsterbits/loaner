import SwiftUI
import SwiftData
import LoanerFeature

@main
struct LoanerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Loan.self, Transaction.self])
    }
}
