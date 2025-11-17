import SwiftUI
import SwiftData

/// Detailed view of a single loan
@available(iOS 17.0, macOS 14.0, *)
struct LoanDetailView: View {
    @Bindable var loan: Loan
    @Environment(\.modelContext) private var context

    @State private var showingAddPayment = false
    @State private var showingAddCapital = false
    @State private var showingExport = false
    @State private var transactionToDelete: Transaction?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            summarySection
            metricsSection
            actionsSection
            transactionsSection
        }
        .navigationTitle(loan.borrowerName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .sheet(isPresented: $showingAddPayment) {
            AddPaymentView(loan: loan)
        }
        .sheet(isPresented: $showingAddCapital) {
            AddCapitalView(loan: loan)
        }
        .sheet(isPresented: $showingExport) {
            ExportView(loan: loan)
        }
        .confirmationDialog(
            "Delete Transaction?",
            isPresented: $showingDeleteConfirmation,
            presenting: transactionToDelete
        ) { transaction in
            Button("Delete '\(transaction.type.displayName)'", role: .destructive) {
                confirmDelete()
            }
            Button("Cancel", role: .cancel) {
                transactionToDelete = nil
            }
        } message: { transaction in
            Text("This \(transaction.type.displayName.lowercased()) transaction will be permanently deleted. The loan balance will be recalculated.")
        }
    }

    // MARK: - Sections

    private var summarySection: some View {
        Section {
            VStack(spacing: 16) {
                // Total Owed
                VStack(spacing: 4) {
                    Text("Total Owed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(loan.totalOwed, format: .currency(code: "USD"))
                        .font(.system(size: 40, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                .accessibilityLabel("Total amount owed: \(loan.totalOwed, format: .currency(code: "USD"))")

                // Principal + Interest Breakdown
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("Principal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(loan.currentPrincipal, format: .currency(code: "USD"))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Current principal amount: \(loan.currentPrincipal, format: .currency(code: "USD"))")

                    VStack(spacing: 4) {
                        Text("Interest")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(loan.accruedInterest, format: .currency(code: "USD"))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    }
                    .accessibilityLabel("Accrued interest amount: \(loan.accruedInterest, format: .currency(code: "USD"))")
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom)
            }
        }
    }

    private var metricsSection: some View {
        Section("Metrics") {
            LabeledContent("Daily Interest") {
                Text(loan.dailyInterestAmount, format: .currency(code: "USD"))
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Daily interest amount: \(loan.dailyInterestAmount, format: .currency(code: "USD"))")

            LabeledContent("Annual Interest") {
                let annual = loan.dailyInterestAmount * 365
                Text(annual, format: .currency(code: "USD"))
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Annual interest amount: \(loan.dailyInterestAmount * 365, format: .currency(code: "USD"))")

            LabeledContent("Interest Rate") {
                Text("\(String(format: "%.2f", loan.annualInterestRate * 100))% APR")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Annual percentage rate: \(String(format: "%.2f", loan.annualInterestRate * 100)) percent")

            LabeledContent("Start Date") {
                Text(loan.startDate, format: .dateTime.month().day().year())
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Loan start date: \(loan.startDate, format: .dateTime.month().day().year())")

            LabeledContent("Days Active") {
                let days = Calendar.current.dateComponents(
                    [.day],
                    from: loan.startDate,
                    to: Date()
                ).day ?? 0
                Text("\(days) days")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Days loan has been active: \(Calendar.current.dateComponents([.day], from: loan.startDate, to: Date()).day ?? 0) days")
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button {
                showingAddPayment = true
            } label: {
                Label("Log Payment", systemImage: "arrow.down.circle.fill")
            }
            .accessibilityLabel("Log a payment for this loan")
            .accessibilityIdentifier("logPaymentButton")

            Button {
                showingAddCapital = true
            } label: {
                Label("Add Investment", systemImage: "plus.circle.fill")
            }
            .accessibilityLabel("Add additional investment to this loan")
            .accessibilityIdentifier("addInvestmentButton")

            Button {
                showingExport = true
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            .accessibilityLabel("Export loan data")
            .accessibilityIdentifier("exportLoanDataButton")
        }
    }

    private var transactionsSection: some View {
        Section("Transaction History") {
            if loan.transactions.isEmpty {
                Text("No transactions yet")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("No transactions recorded for this loan")
            } else {
                ForEach(loan.sortedTransactions) { transaction in
                    TransactionRowView(transaction: transaction)
                }
                .onDelete(perform: deleteTransaction)
            }
        }
    }

    // MARK: - Actions

    private func deleteTransaction(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        transactionToDelete = loan.sortedTransactions[index]
        showingDeleteConfirmation = true
    }

    private func confirmDelete() {
        guard let transaction = transactionToDelete else { return }
        context.delete(transaction)
        transactionToDelete = nil
    }
}

/// Row view for a transaction
struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: transaction.type.icon)
                    .foregroundStyle(iconColor)

                Text(transaction.type.displayName)
                    .font(.headline)

                Spacer()

                Text(transaction.displayDescription)
                    .font(.headline)
                    .foregroundStyle(textColor)
            }
            .accessibilityLabel("\(transaction.type.displayName): \(transaction.displayDescription)")

            HStack {
                Text(transaction.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !transaction.notes.isEmpty {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(transaction.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .accessibilityLabel("Transaction date: \(transaction.formattedDate)\(transaction.notes.isEmpty ? "" : ". Notes: \(transaction.notes)")")

            // Show split for payments
            if case .payment(let principal, let interest) = transaction.type {
                if principal > 0 && interest > 0 {
                    HStack(spacing: 12) {
                        Label {
                            Text(principal, format: .currency(code: "USD"))
                        } icon: {
                            Text("P:")
                        }
                        .font(.caption2)
                        .foregroundStyle(.blue)

                        Label {
                            Text(interest, format: .currency(code: "USD"))
                        } icon: {
                            Text("I:")
                        }
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    }
                    .accessibilityLabel("Payment breakdown: \(principal, format: .currency(code: "USD")) principal, \(interest, format: .currency(code: "USD")) interest")
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var iconColor: Color {
        switch transaction.type {
        case .capitalAddition:
            return .green
        case .payment:
            return .blue
        }
    }

    private var textColor: Color {
        switch transaction.type {
        case .capitalAddition:
            return .green
        case .payment:
            return .blue
        }
    }
}
