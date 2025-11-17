import SwiftUI

/// First-launch onboarding experience
@available(iOS 17.0, macOS 14.0, *)
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // App icon placeholder
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Welcome to Loaner")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Track loans where you're the lender")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Daily Interest Calculations",
                        description: "Automatically calculate compounding interest on your loans"
                    )

                    FeatureRow(
                        icon: "list.bullet.rectangle",
                        title: "Payment Tracking",
                        description: "Log payments and see how they reduce principal and interest"
                    )

                    FeatureRow(
                        icon: "doc.text",
                        title: "Tax Reports",
                        description: "Export transaction history for tax reporting"
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 32)
                .accessibilityLabel("Get started with Loaner")
            }
            .padding(.vertical, 32)
        }
    }
}

/// Feature row for onboarding
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}
