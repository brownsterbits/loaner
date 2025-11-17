import SwiftUI
import SwiftData

/// View for adding a new loan
@available(iOS 17.0, macOS 14.0, *)
struct AddLoanView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var borrowerName = ""
    @State private var startDate = Date()
    @State private var initialAmount = ""
    @State private var annualRate = "8.0"
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Loan Details") {
                    TextField("Borrower Name", text: $borrowerName)
                        .accessibilityLabel("Borrower name")
                        .accessibilityIdentifier("borrowerNameField")

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .accessibilityLabel("Loan start date")
                        .accessibilityIdentifier("loanStartDatePicker")

                    TextField("Initial Investment", text: $initialAmount)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .accessibilityLabel("Initial investment amount")
                        .accessibilityIdentifier("initialAmountField")

                    HStack {
                        TextField("Interest Rate", text: $annualRate)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .accessibilityLabel("Annual interest rate percentage")
                            .accessibilityIdentifier("interestRateField")
                        Text("%")
                            .foregroundStyle(.secondary)
                    }

                    Text("Interest compounds daily")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Loan notes")
                        .accessibilityIdentifier("loanNotesField")
                }
            }
            .navigationTitle("New Loan")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel adding loan")
                    .accessibilityIdentifier("cancelLoanButton")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addLoan()
                    }
                    .disabled(!isValid)
                    .accessibilityLabel("Add new loan")
                    .accessibilityIdentifier("addLoanButton")
                }
            }

            if let message = validationMessage {
                Text(message)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
    }

    private var isValid: Bool {
        guard !borrowerName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let amount = Decimal(string: initialAmount), amount > 0 else { return false }
        guard let rate = Double(annualRate), rate >= 0, rate <= 100 else { return false }
        guard startDate <= Date() else { return false } // Can't start loan in the future
        return true
    }

    private var validationMessage: String? {
        if borrowerName.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Borrower name is required"
        }
        if Decimal(string: initialAmount) == nil {
            return "Please enter a valid initial amount"
        }
        if let amount = Decimal(string: initialAmount), amount <= 0 {
            return "Initial amount must be greater than zero"
        }
        if Double(annualRate) == nil {
            return "Please enter a valid interest rate"
        }
        if let rate = Double(annualRate), rate < 0 {
            return "Interest rate cannot be negative"
        }
        if let rate = Double(annualRate), rate < 0.1 {
            return "Interest rate seems too low (minimum 0.1%)"
        }
        if let rate = Double(annualRate), rate > 50 {
            return "Interest rate seems too high (maximum 50%)"
        }
        if startDate > Date() {
            return "Start date cannot be in the future"
        }
        return nil
    }

    private func addLoan() {
        guard let initial = Decimal(string: initialAmount),
              let rate = Double(annualRate) else {
            return
        }

        let loan = Loan(
            borrowerName: borrowerName,
            startDate: startDate,
            annualInterestRate: rate / 100.0,
            notes: notes
        )

        // Add initial investment transaction
        let transaction = Transaction(
            date: startDate,
            type: .capitalAddition(amount: initial)
        )
        transaction.loan = loan
        loan.transactions.append(transaction)

        context.insert(loan)
        context.insert(transaction)

        dismiss()
    }
}
