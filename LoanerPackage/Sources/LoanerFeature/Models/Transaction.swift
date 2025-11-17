import Foundation
import SwiftData

/// Represents a transaction on a loan (either adding capital or making a payment)
@Model
@available(iOS 17.0, macOS 14.0, *)
public final class Transaction {
    /// Unique identifier
    public var id: UUID

    /// Date of the transaction
    public var date: Date

    /// Transaction type discriminator (0 = capital addition, 1 = payment)
    public var typeRaw: Int

    /// Amount for capital additions or total payment amount
    public var amount: Decimal

    /// For payments: amount applied to principal
    public var principalAmount: Decimal

    /// For payments: amount applied to interest
    public var interestAmount: Decimal

    /// Optional notes about the transaction
    public var notes: String

    /// The loan this transaction belongs to
    public var loan: Loan?

    public init(
        date: Date,
        type: TransactionType,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.notes = notes

        switch type {
        case .capitalAddition(let amount):
            self.typeRaw = 0
            self.amount = amount
            self.principalAmount = 0
            self.interestAmount = 0
        case .payment(let principal, let interest):
            self.typeRaw = 1
            self.amount = principal + interest
            self.principalAmount = principal
            self.interestAmount = interest
        }
    }

    /// Computed property to access the transaction type
    public var type: TransactionType {
        get {
            switch typeRaw {
            case 0:
                return .capitalAddition(amount: amount)
            case 1:
                return .payment(appliedToPrincipal: principalAmount, appliedToInterest: interestAmount)
            default:
                return .capitalAddition(amount: 0)
            }
        }
        set {
            switch newValue {
            case .capitalAddition(let amount):
                self.typeRaw = 0
                self.amount = amount
                self.principalAmount = 0
                self.interestAmount = 0
            case .payment(let principal, let interest):
                self.typeRaw = 1
                self.amount = principal + interest
                self.principalAmount = principal
                self.interestAmount = interest
            }
        }
    }
}

// MARK: - Transaction Type

public enum TransactionType: Codable, Equatable {
    case capitalAddition(amount: Decimal)
    case payment(appliedToPrincipal: Decimal, appliedToInterest: Decimal)

    var displayName: String {
        switch self {
        case .capitalAddition:
            return "Investment"
        case .payment:
            return "Payment"
        }
    }

    var icon: String {
        switch self {
        case .capitalAddition:
            return "arrow.down.circle.fill"
        case .payment:
            return "arrow.up.circle.fill"
        }
    }

    var totalAmount: Decimal {
        switch self {
        case .capitalAddition(let amount):
            return amount
        case .payment(let principal, let interest):
            return principal + interest
        }
    }
}

// MARK: - Transaction Extensions

extension Transaction {
    /// Formatted date string
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    /// Description of the transaction for display
    var displayDescription: String {
        switch type {
        case .capitalAddition(let amount):
            return "+\(amount.formatted(.currency(code: "USD")))"
        case .payment(let principal, let interest):
            let total = principal + interest
            if principal > 0 && interest > 0 {
                return "-\(total.formatted(.currency(code: "USD"))) (Split)"
            } else if principal > 0 {
                return "-\(principal.formatted(.currency(code: "USD"))) (Principal)"
            } else {
                return "-\(interest.formatted(.currency(code: "USD"))) (Interest)"
            }
        }
    }
}
