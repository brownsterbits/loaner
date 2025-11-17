import SwiftUI
import SwiftData

/// Main dashboard showing all loans
@available(iOS 17.0, macOS 14.0, *)
struct LoanListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Loan.createdAt, order: .reverse) private var loans: [Loan]

    @State private var showingAddLoan = false
    @State private var showingImport = false
    @State private var loanToDelete: Loan?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if loans.isEmpty {
                    emptyState
                } else {
                    loansList
                }
            }
            .navigationTitle("Loans")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button {
                            showingAddLoan = true
                        } label: {
                            Label("Create New Loan", systemImage: "plus")
                        }

                        Button {
                            showingImport = true
                        } label: {
                            Label("Import from CSV", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add loan options")
                }
            }
            .sheet(isPresented: $showingAddLoan) {
                AddLoanView()
            }
            .sheet(isPresented: $showingImport) {
                ImportView()
            }
            .confirmationDialog(
                "Delete Loan?",
                isPresented: $showingDeleteConfirmation,
                presenting: loanToDelete
            ) { loan in
                Button("Delete '\(loan.borrowerName)'", role: .destructive) {
                    confirmDelete()
                }
                Button("Cancel", role: .cancel) {
                    loanToDelete = nil
                }
            } message: { loan in
                Text("This loan and all \(loan.transactions.count) transaction(s) will be permanently deleted.")
            }
        }
    }

    // MARK: - Views

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Loans Yet", systemImage: "dollarsign.circle")
        } description: {
            VStack(spacing: 8) {
                Text("Track loans where you're the lender")
                    .font(.subheadline)
                Text("Calculate daily interest • Log payments • Tax reports")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } actions: {
            VStack(spacing: 12) {
                Button("Add Your First Loan") {
                    showingAddLoan = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Create your first loan")
                .accessibilityIdentifier("addFirstLoanButton")

                Button("Try Sample Loan") {
                    createSampleLoan()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Create a sample loan to explore the app")
                .accessibilityIdentifier("trySampleLoanButton")
            }
        }
    }

    private var loansList: some View {
        List {
            ForEach(loans) { loan in
                NavigationLink(value: loan) {
                    LoanRowView(loan: loan)
                }
            }
            .onDelete(perform: deleteLoans)
        }
        .navigationDestination(for: Loan.self) { loan in
            LoanDetailView(loan: loan)
        }
    }

    // MARK: - Actions

    private func deleteLoans(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        loanToDelete = loans[index]
        showingDeleteConfirmation = true
    }

    private func confirmDelete() {
        guard let loan = loanToDelete else { return }
        context.delete(loan)
        loanToDelete = nil
    }

    private func createSampleLoan() {
        // Create a sample loan starting 90 days ago
        let startDate = Calendar.current.date(byAdding: .day, value: -90, to: Date())!

        let sampleLoan = Loan(
            borrowerName: "Sample: Alex Johnson",
            startDate: startDate,
            annualInterestRate: 0.08, // 8% APR
            notes: "This is a sample loan to help you explore the app. Feel free to delete it when you're ready to add your own loans."
        )

        // Initial investment of $10,000
        let initialTransaction = Transaction(
            date: startDate,
            type: .capitalAddition(amount: 10000),
            notes: "Initial loan"
        )
        initialTransaction.loan = sampleLoan
        sampleLoan.transactions.append(initialTransaction)

        // Additional capital 30 days ago
        let additionalCapitalDate = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        let additionalCapital = Transaction(
            date: additionalCapitalDate,
            type: .capitalAddition(amount: 2500),
            notes: "Additional investment"
        )
        additionalCapital.loan = sampleLoan
        sampleLoan.transactions.append(additionalCapital)

        // Payment 15 days ago
        let paymentDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        let payment = Transaction(
            date: paymentDate,
            type: .payment(appliedToPrincipal: 300, appliedToInterest: 200),
            notes: "First payment received"
        )
        payment.loan = sampleLoan
        sampleLoan.transactions.append(payment)

        context.insert(sampleLoan)
        context.insert(initialTransaction)
        context.insert(additionalCapital)
        context.insert(payment)

        try? context.save()
    }
}

/// Row view for a single loan in the list
struct LoanRowView: View {
    let loan: Loan

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loan.borrowerName)
                .font(.headline)
                .accessibilityLabel("Loan to \(loan.borrowerName)")

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Owed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(loan.totalOwed, format: .currency(code: "USD"))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Total amount owed: \(loan.totalOwed, format: .currency(code: "USD"))")

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Daily Interest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(loan.dailyInterestAmount, format: .currency(code: "USD"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Daily interest amount: \(loan.dailyInterestAmount, format: .currency(code: "USD"))")
            }

            HStack {
                Label(
                    "\(String(format: "%.1f", loan.annualInterestRate * 100))% APR",
                    systemImage: "percent"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Annual percentage rate: \(String(format: "%.1f", loan.annualInterestRate * 100)) percent")

                Spacer()

                Text("Since \(loan.startDate, format: .dateTime.year().month())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Loan started in \(loan.startDate, format: .dateTime.year().month())")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loan summary for \(loan.borrowerName)")
        .accessibilityValue("Total owed: \(loan.totalOwed, format: .currency(code: "USD")), daily interest: \(loan.dailyInterestAmount, format: .currency(code: "USD")), \(String(format: "%.1f", loan.annualInterestRate * 100))% APR, started \(loan.startDate, format: .dateTime.year().month())")
    }
}
