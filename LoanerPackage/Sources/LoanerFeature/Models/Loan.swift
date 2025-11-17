import Foundation
import SwiftData

/// Represents a loan or investment where you are the lender tracking what is owed to you
@Model
@available(iOS 17.0, macOS 14.0, *)
public final class Loan {
    /// Unique identifier
    public var id: UUID

    /// Name of the borrower or company
    public var borrowerName: String

    /// Date the loan started
    public var startDate: Date

    /// Annual interest rate (e.g., 0.08 for 8%)
    public var annualInterestRate: Double

    /// Optional notes about the loan
    public var notes: String

    /// All transactions for this loan (capital additions and payments)
    @Relationship(deleteRule: .cascade, inverse: \Transaction.loan)
    public var transactions: [Transaction]

    /// Date loan was created in the app
    public var createdAt: Date

    public init(
        borrowerName: String,
        startDate: Date,
        annualInterestRate: Double,
        notes: String = ""
    ) {
        self.id = UUID()
        self.borrowerName = borrowerName
        self.startDate = startDate
        self.annualInterestRate = annualInterestRate
        self.notes = notes
        self.transactions = []
        self.createdAt = Date()
    }
}

// MARK: - Computed Properties

extension Loan {
    /// Current principal balance (sum of capital additions minus principal payments)
    public var currentPrincipal: Decimal {
        transactions.reduce(Decimal.zero) { total, transaction in
            switch transaction.type {
            case .capitalAddition(let amount):
                return total + amount
            case .payment(let toPrincipal, _):
                return total - toPrincipal
            }
        }
    }

    /// Interest accrued since last interest payment
    public var accruedInterest: Decimal {
        LoanCalculator.calculateAccruedInterest(for: self, asOf: Date())
    }

    /// Total amount owed (principal + accrued interest)
    public var totalOwed: Decimal {
        currentPrincipal + accruedInterest
    }

    /// Daily interest amount based on current principal
    public var dailyInterestAmount: Decimal {
        LoanCalculator.calculateDailyInterest(
            principal: currentPrincipal,
            annualRate: annualInterestRate
        )
    }

    /// Total interest paid over the lifetime of the loan (for tax reporting)
    public var lifetimeInterestPaid: Decimal {
        transactions.reduce(Decimal.zero) { total, transaction in
            switch transaction.type {
            case .payment(_, let toInterest):
                return total + toInterest
            case .capitalAddition:
                return total
            }
        }
    }

    /// Total principal paid back over the lifetime of the loan
    public var lifetimePrincipalPaid: Decimal {
        transactions.reduce(Decimal.zero) { total, transaction in
            switch transaction.type {
            case .payment(let toPrincipal, _):
                return total + toPrincipal
            case .capitalAddition:
                return total
            }
        }
    }

    /// Total capital invested (sum of all capital additions)
    public var totalInvested: Decimal {
        transactions.reduce(Decimal.zero) { total, transaction in
            switch transaction.type {
            case .capitalAddition(let amount):
                return total + amount
            case .payment:
                return total
            }
        }
    }

    /// Transactions sorted by date (most recent first)
    public var sortedTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }
    }
}

