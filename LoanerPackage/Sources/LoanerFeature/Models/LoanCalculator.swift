import Foundation

/// Handles all loan calculation logic including daily compound interest
enum LoanCalculator {

    // MARK: - Interest Calculations

    /// Calculate accrued interest for a loan as of a specific date
    /// - Parameters:
    ///   - loan: The loan to calculate interest for
    ///   - asOf: The date to calculate interest up to
    /// - Returns: Total accrued interest
    static func calculateAccruedInterest(for loan: Loan, asOf date: Date) -> Decimal {
        // Get all transactions sorted by date (oldest first)
        let sortedTransactions = loan.transactions.sorted { $0.date < $1.date }

        var currentPrincipal = Decimal.zero
        var accruedInterest = Decimal.zero
        var lastDate = loan.startDate

        // Process each transaction chronologically
        for transaction in sortedTransactions {
            // Calculate interest accrued from last date to this transaction date
            let daysElapsed = transaction.date.timeIntervalSince(lastDate) / 86400
            if daysElapsed > 0 {
                let interestForPeriod = calculateInterestForPeriod(
                    principal: currentPrincipal,
                    annualRate: loan.annualInterestRate,
                    days: daysElapsed
                )
                accruedInterest += interestForPeriod
            }

            // Apply the transaction
            switch transaction.type {
            case .capitalAddition(let amount):
                currentPrincipal += amount

            case .payment(let toPrincipal, let toInterest):
                // Interest payment reduces accrued interest
                accruedInterest -= toInterest
                // Principal payment reduces principal
                currentPrincipal -= toPrincipal
            }

            lastDate = transaction.date
        }

        // Calculate interest from last transaction to the target date
        let finalDays = date.timeIntervalSince(lastDate) / 86400
        if finalDays > 0 {
            let finalInterest = calculateInterestForPeriod(
                principal: currentPrincipal,
                annualRate: loan.annualInterestRate,
                days: finalDays
            )
            accruedInterest += finalInterest
        }

        return max(accruedInterest, 0) // Never negative
    }

    /// Calculate daily interest amount for a given principal
    /// - Parameters:
    ///   - principal: The principal amount
    ///   - annualRate: Annual interest rate (e.g., 0.08 for 8%)
    /// - Returns: Daily interest amount
    static func calculateDailyInterest(
        principal: Decimal,
        annualRate: Double
    ) -> Decimal {
        let dailyRate = Decimal(annualRate) / 365
        return principal * dailyRate
    }

    /// Calculate interest for a specific number of days
    /// - Parameters:
    ///   - principal: The principal amount
    ///   - annualRate: Annual interest rate
    ///   - days: Number of days to calculate interest for
    /// - Returns: Total interest for the period
    private static func calculateInterestForPeriod(
        principal: Decimal,
        annualRate: Double,
        days: Double
    ) -> Decimal {
        // Daily compounding: calculate daily rate and multiply by days
        let dailyRate = Decimal(annualRate) / 365
        return principal * dailyRate * Decimal(days)
    }

    // MARK: - Payment Calculations

    /// Calculate how a payment should be split between interest and principal
    /// - Parameters:
    ///   - paymentAmount: Total payment amount
    ///   - accruedInterest: Current accrued interest
    ///   - strategy: Payment allocation strategy
    /// - Returns: Tuple of (principal payment, interest payment)
    static func calculatePaymentSplit(
        paymentAmount: Decimal,
        accruedInterest: Decimal,
        strategy: PaymentStrategy
    ) -> (principal: Decimal, interest: Decimal) {
        switch strategy {
        case .interestFirst:
            // Pay interest first, remainder goes to principal
            if paymentAmount <= accruedInterest {
                return (principal: 0, interest: paymentAmount)
            } else {
                let remainingForPrincipal = paymentAmount - accruedInterest
                return (principal: remainingForPrincipal, interest: accruedInterest)
            }

        case .principalOnly:
            return (principal: paymentAmount, interest: 0)

        case .custom(let principalAmount, let interestAmount):
            return (principal: principalAmount, interest: interestAmount)
        }
    }

    /// Preview the impact of a payment before applying it
    /// - Parameters:
    ///   - loan: The loan to preview payment for
    ///   - amount: Payment amount
    ///   - strategy: Payment allocation strategy
    ///   - date: Date of the payment
    /// - Returns: Payment impact details
    static func previewPayment(
        for loan: Loan,
        amount: Decimal,
        strategy: PaymentStrategy,
        date: Date
    ) -> PaymentImpact {
        let currentPrincipal = loan.currentPrincipal
        let currentInterest = calculateAccruedInterest(for: loan, asOf: date)
        let currentTotal = currentPrincipal + currentInterest
        let currentDailyInterest = calculateDailyInterest(
            principal: currentPrincipal,
            annualRate: loan.annualInterestRate
        )

        let split = calculatePaymentSplit(
            paymentAmount: amount,
            accruedInterest: currentInterest,
            strategy: strategy
        )

        let newPrincipal = currentPrincipal - split.principal
        let newInterest = currentInterest - split.interest
        let newTotal = newPrincipal + newInterest
        let newDailyInterest = calculateDailyInterest(
            principal: newPrincipal,
            annualRate: loan.annualInterestRate
        )

        return PaymentImpact(
            paymentAmount: amount,
            appliedToPrincipal: split.principal,
            appliedToInterest: split.interest,
            principalBefore: currentPrincipal,
            principalAfter: newPrincipal,
            interestBefore: currentInterest,
            interestAfter: newInterest,
            totalBefore: currentTotal,
            totalAfter: newTotal,
            dailyInterestBefore: currentDailyInterest,
            dailyInterestAfter: newDailyInterest
        )
    }
}

// MARK: - Supporting Types

enum PaymentStrategy: Hashable, Equatable {
    case interestFirst
    case principalOnly
    case custom(principal: Decimal, interest: Decimal)
}

struct PaymentImpact {
    let paymentAmount: Decimal
    let appliedToPrincipal: Decimal
    let appliedToInterest: Decimal

    let principalBefore: Decimal
    let principalAfter: Decimal

    let interestBefore: Decimal
    let interestAfter: Decimal

    let totalBefore: Decimal
    let totalAfter: Decimal

    let dailyInterestBefore: Decimal
    let dailyInterestAfter: Decimal

    var principalChange: Decimal {
        principalAfter - principalBefore
    }

    var interestChange: Decimal {
        interestAfter - interestBefore
    }

    var totalChange: Decimal {
        totalAfter - totalBefore
    }

    var dailyInterestChange: Decimal {
        dailyInterestAfter - dailyInterestBefore
    }
}
