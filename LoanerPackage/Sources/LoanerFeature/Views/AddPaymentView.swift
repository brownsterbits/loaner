import SwiftUI
import SwiftData

/// View for logging a payment on a loan
@available(iOS 17.0, macOS 14.0, *)
struct AddPaymentView: View {
    let loan: Loan

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var amount = ""
    @State private var paymentStrategy: PaymentStrategy = .interestFirst
    @State private var customPrincipal = ""
    @State private var customInterest = ""
    @State private var notes = ""

    @State private var preview: PaymentImpact?

    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityLabel("Payment date")
                        .accessibilityIdentifier("paymentDatePicker")

                    TextField("Amount", text: $amount)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .accessibilityLabel("Payment amount")
                        .accessibilityIdentifier("paymentAmountField")
                        .onChange(of: amount) { _, _ in
                            updatePreview()
                        }
                }

                Section {
                    HStack {
                        Text("Apply To")
                        Spacer()
                        HelpButton(
                            title: "Payment Strategies",
                            message: "Interest First: Standard practice. Pays accrued interest first, then remainder to principal. Your daily interest rate stays the same.\n\nPrincipal Only: Aggressive paydown. Entire payment reduces principal. Your daily interest rate drops immediately."
                        )
                    }

                    Picker("Strategy", selection: $paymentStrategy) {
                        Text("Interest First").tag(PaymentStrategy.interestFirst)
                        Text("Principal Only").tag(PaymentStrategy.principalOnly)
                        Text("Custom Split").tag(PaymentStrategy.custom(principal: 0, interest: 0))
                    }
                    .accessibilityLabel("Payment application strategy")
                    .accessibilityIdentifier("paymentStrategyPicker")
                    .onChange(of: paymentStrategy) { _, _ in
                        updatePreview()
                    }

                    if case .custom = paymentStrategy {
                        TextField("To Principal", text: $customPrincipal)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .accessibilityLabel("Amount to apply to principal")
                            .accessibilityIdentifier("customPrincipalField")
                            .onChange(of: customPrincipal) { _, _ in
                                updatePreview()
                            }

                        TextField("To Interest", text: $customInterest)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .accessibilityLabel("Amount to apply to interest")
                            .accessibilityIdentifier("customInterestField")
                            .onChange(of: customInterest) { _, _ in
                                updatePreview()
                            }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Payment notes")
                        .accessibilityIdentifier("paymentNotesField")
                }

                if let preview = preview {
                    impactSection(preview)
                }

                if let message = validationMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .accessibilityLabel("Validation error")
                            .accessibilityIdentifier("validationMessage")
                    }
                }
            }
            .navigationTitle("Log Payment")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel payment")
                    .accessibilityIdentifier("cancelPaymentButton")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePayment()
                    }
                    .disabled(!isValid)
                    .accessibilityLabel("Save payment")
                    .accessibilityIdentifier("savePaymentButton")
                }
            }
            .onAppear {
                updatePreview()
            }
        }
    }

    // MARK: - Preview Section

    private func impactSection(_ impact: PaymentImpact) -> some View {
        Section("Impact Preview") {
            Group {
                LabeledContent("Principal") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(impact.principalBefore, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(impact.principalAfter, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    .font(.caption)
                }
                .accessibilityLabel("Principal balance change from \(impact.principalBefore.formatted(.currency(code: "USD"))) to \(impact.principalAfter.formatted(.currency(code: "USD")))")

                LabeledContent("Interest") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(impact.interestBefore, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(impact.interestAfter, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    }
                    .font(.caption)
                }
                .accessibilityLabel("Interest balance change from \(impact.interestBefore.formatted(.currency(code: "USD"))) to \(impact.interestAfter.formatted(.currency(code: "USD")))")

                LabeledContent("Total Owed") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(impact.totalBefore, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(impact.totalAfter, format: .currency(code: "USD"))
                            .fontWeight(.bold)
                    }
                    .font(.caption)
                }
                .accessibilityLabel("Total amount owed change from \(impact.totalBefore.formatted(.currency(code: "USD"))) to \(impact.totalAfter.formatted(.currency(code: "USD")))")

                LabeledContent("Daily Interest") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(impact.dailyInterestBefore, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                        if impact.dailyInterestChange != 0 {
                            Image(systemName: "arrow.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(impact.dailyInterestAfter, format: .currency(code: "USD"))
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                    }
                    .font(.caption)
                }
                .accessibilityLabel("Daily interest change from \(impact.dailyInterestBefore.formatted(.currency(code: "USD"))) to \(impact.dailyInterestAfter.formatted(.currency(code: "USD")))")
            }

            // Payment allocation summary
            VStack(alignment: .leading, spacing: 4) {
                Text("Payment Allocation")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    if impact.appliedToPrincipal > 0 {
                        Label {
                            Text(impact.appliedToPrincipal, format: .currency(code: "USD"))
                        } icon: {
                            Text("Principal:")
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .accessibilityLabel("\(impact.appliedToPrincipal.formatted(.currency(code: "USD"))) applied to principal")
                    }

                    if impact.appliedToInterest > 0 {
                        Label {
                            Text(impact.appliedToInterest, format: .currency(code: "USD"))
                        } icon: {
                            Text("Interest:")
                        }
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .accessibilityLabel("\(impact.appliedToInterest.formatted(.currency(code: "USD"))) applied to interest")
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Payment allocation: \(impact.appliedToPrincipal.formatted(.currency(code: "USD"))) to principal, \(impact.appliedToInterest.formatted(.currency(code: "USD"))) to interest")
            }
        }
    }

    // MARK: - Logic

    private var isValid: Bool {
        guard let paymentAmount = Decimal(string: amount), paymentAmount > 0 else {
            return false
        }

        if case .custom = paymentStrategy {
            guard let principal = Decimal(string: customPrincipal),
                  let interest = Decimal(string: customInterest),
                  principal >= 0, interest >= 0,
                  principal + interest == paymentAmount else {
                return false
            }
        }

        return true
    }

    private var validationMessage: String? {
        guard let paymentAmount = Decimal(string: amount) else {
            return "Please enter a valid payment amount"
        }

        if paymentAmount <= 0 {
            return "Payment amount must be greater than zero"
        }

        if date < loan.startDate {
            return "Payment date cannot be before loan start date (\(loan.startDate.formatted(date: .abbreviated, time: .omitted)))"
        }

        if date > Date() {
            return "Payment date cannot be in the future"
        }

        if case .custom = paymentStrategy {
            guard let principal = Decimal(string: customPrincipal) else {
                return "Please enter a valid principal amount"
            }
            guard let interest = Decimal(string: customInterest) else {
                return "Please enter a valid interest amount"
            }

            if principal < 0 || interest < 0 {
                return "Amounts cannot be negative"
            }

            if principal + interest != paymentAmount {
                return "Principal + Interest must equal total payment amount"
            }
        }

        return nil
    }

    private func updatePreview() {
        guard let paymentAmount = Decimal(string: amount), paymentAmount > 0 else {
            preview = nil
            return
        }

        let strategy: PaymentStrategy
        if case .custom = paymentStrategy,
           let principal = Decimal(string: customPrincipal),
           let interest = Decimal(string: customInterest) {
            strategy = .custom(principal: principal, interest: interest)
        } else {
            strategy = paymentStrategy
        }

        preview = LoanCalculator.previewPayment(
            for: loan,
            amount: paymentAmount,
            strategy: strategy,
            date: date
        )
    }

    private func savePayment() {
        guard let impact = preview else { return }

        let transaction = Transaction(
            date: date,
            type: .payment(
                appliedToPrincipal: impact.appliedToPrincipal,
                appliedToInterest: impact.appliedToInterest
            ),
            notes: notes
        )

        transaction.loan = loan
        loan.transactions.append(transaction)
        context.insert(transaction)

        dismiss()
    }
}
