import SwiftUI
import SwiftData

/// View for adding capital to an existing loan
@available(iOS 17.0, macOS 14.0, *)
struct AddCapitalView: View {
    let loan: Loan

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var amount = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Investment Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityLabel("Investment date")
                        .accessibilityIdentifier("capitalDatePicker")

                    TextField("Amount", text: $amount)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .accessibilityLabel("Investment amount")
                        .accessibilityIdentifier("capitalAmountField")
                }

                if let additionAmount = Decimal(string: amount), additionAmount > 0 {
                    Section("Impact") {
                        LabeledContent("Current Principal") {
                            Text(loan.currentPrincipal, format: .currency(code: "USD"))
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Current loan principal amount")

                        LabeledContent("New Principal") {
                            let newPrincipal = loan.currentPrincipal + additionAmount
                            Text(newPrincipal, format: .currency(code: "USD"))
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                        }
                        .accessibilityLabel("New loan principal after investment")

                        LabeledContent("Current Daily Interest") {
                            Text(loan.dailyInterestAmount, format: .currency(code: "USD"))
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Current daily interest amount")

                        LabeledContent("New Daily Interest") {
                            let newPrincipal = loan.currentPrincipal + additionAmount
                            let newDaily = LoanCalculator.calculateDailyInterest(
                                principal: newPrincipal,
                                annualRate: loan.annualInterestRate
                            )
                            Text(newDaily, format: .currency(code: "USD"))
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                        .accessibilityLabel("New daily interest after investment")

                        let increase = LoanCalculator.calculateDailyInterest(
                            principal: additionAmount,
                            annualRate: loan.annualInterestRate
                        )
                        let annualIncrease = increase * 365

                        Text("This will add \(increase, format: .currency(code: "USD"))/day or \(annualIncrease, format: .currency(code: "USD"))/year in interest.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Investment impact summary showing daily and annual interest increase")
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Investment notes")
                        .accessibilityIdentifier("capitalNotesField")
                }
            }
            .navigationTitle("Add Investment")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel adding investment")
                    .accessibilityIdentifier("cancelCapitalButton")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCapital()
                    }
                    .disabled(!isValid)
                    .accessibilityLabel("Add investment to loan")
                    .accessibilityIdentifier("addCapitalButton")
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
        guard let additionAmount = Decimal(string: amount), additionAmount > 0 else {
            return false
        }
        guard date >= loan.startDate else {
            return false
        }
        return true
    }

    private var validationMessage: String? {
        guard let additionAmount = Decimal(string: amount) else {
            return "Please enter a valid amount"
        }

        if additionAmount <= 0 {
            return "Amount must be greater than zero"
        }

        if date < loan.startDate {
            return "Investment date cannot be before loan start date (\(loan.startDate.formatted(date: .abbreviated, time: .omitted)))"
        }

        if date > Date() {
            return "Investment date cannot be in the future"
        }

        return nil
    }

    private func addCapital() {
        guard let additionAmount = Decimal(string: amount) else {
            return
        }

        let transaction = Transaction(
            date: date,
            type: .capitalAddition(amount: additionAmount),
            notes: notes
        )

        transaction.loan = loan
        loan.transactions.append(transaction)
        context.insert(transaction)

        dismiss()
    }
}
