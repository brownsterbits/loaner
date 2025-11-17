import Testing
@testable import LoanerFeature
import Foundation

// MARK: - LoanCalculator Tests

@Test func testDailyInterestCalculation() async throws {
    // Test basic daily interest calculation
    let principal: Decimal = 10000
    let annualRate: Double = 0.05 // 5%
    
    let dailyInterest = LoanCalculator.calculateDailyInterest(
        principal: principal,
        annualRate: annualRate,
        compoundingFrequency: .daily
    )
    
    // Expected: 10000 * 0.05 / 365 ≈ 1.37 per day
    let expectedDaily = principal * Decimal(annualRate) / 365
    #expect(abs(dailyInterest - expectedDaily) < 0.01)
}

@Test func testAccruedInterestCalculation() async throws {
    // Create a test loan
    let loan = Loan(
        borrowerName: "Test Loan",
        startDate: Date().addingTimeInterval(-30 * 24 * 3600), // 30 days ago
        annualInterestRate: 0.05,
        compoundingFrequency: .daily,
        status: .active,
        notes: ""
    )
    
    let accrued = LoanCalculator.calculateAccruedInterest(for: loan, asOf: Date())
    
    // Should have accrued some interest over 30 days
    #expect(accrued >= 0)
    
    // Principal starts at 0, so accrued should be 0 for a loan with no capital
    #expect(accrued == 0)
}

@Test func testMonthlyCompoundingInterest() async throws {
    let principal: Decimal = 10000
    let annualRate: Double = 0.06 // 6%
    
    let dailyInterest = LoanCalculator.calculateDailyInterest(
        principal: principal,
        annualRate: annualRate,
        compoundingFrequency: .monthly
    )
    
    // Should be positive
    #expect(dailyInterest > 0)
    
    // Should be different from daily compounding
    let dailyCompounded = LoanCalculator.calculateDailyInterest(
        principal: principal,
        annualRate: annualRate,
        compoundingFrequency: .daily
    )
    
    #expect(dailyInterest != dailyCompounded)
}

@Test func testAnnualCompoundingInterest() async throws {
    let principal: Decimal = 10000
    let annualRate: Double = 0.07 // 7%
    
    let dailyInterest = LoanCalculator.calculateDailyInterest(
        principal: principal,
        annualRate: annualRate,
        compoundingFrequency: .annually
    )
    
    // Should be positive
    #expect(dailyInterest > 0)
    
    // Should be different from daily compounding
    let dailyCompounded = LoanCalculator.calculateDailyInterest(
        principal: principal,
        annualRate: annualRate,
        compoundingFrequency: .daily
    )
    
    #expect(dailyInterest != dailyCompounded)
}

// MARK: - Model Tests

@Test func testLoanInitialization() async throws {
    let loan = Loan(
        borrowerName: "Test Loan",
        startDate: Date(),
        annualInterestRate: 0.05,
        compoundingFrequency: .monthly,
        status: .active,
        notes: "Test notes"
    )
    
    #expect(loan.borrowerName == "Test Loan")
    #expect(loan.annualInterestRate == 0.05)
    #expect(loan.compoundingFrequency == .monthly)
    #expect(loan.status == .active)
    #expect(loan.notes == "Test notes")
    #expect(loan.transactions.isEmpty)
    #expect(loan.currentPrincipal == 0)
    #expect(loan.totalOwed == 0) // No principal, no interest
}

@Test func testTransactionCreation() async throws {
    let date = Date()
    
    // Test capital addition
    let capitalTransaction = Transaction(
        date: date,
        type: .capitalAddition(amount: 1000),
        notes: "Initial investment"
    )
    
    #expect(capitalTransaction.date == date)
    #expect(capitalTransaction.notes == "Initial investment")
    
    if case .capitalAddition(let amount) = capitalTransaction.type {
        #expect(amount == 1000)
    } else {
        #expect(Bool(false), "Expected capital addition transaction")
    }
    
    // Test payment transaction
    let paymentTransaction = Transaction(
        date: date,
        type: .payment(appliedToPrincipal: 100, appliedToInterest: 50),
        notes: "Monthly payment"
    )
    
    #expect(paymentTransaction.date == date)
    #expect(paymentTransaction.notes == "Monthly payment")
    
    if case .payment(let principal, let interest) = paymentTransaction.type {
        #expect(principal == 100)
        #expect(interest == 50)
    } else {
        #expect(Bool(false), "Expected payment transaction")
    }
}

@Test func testLoanWithTransactions() async throws {
    let loan = Loan(
        borrowerName: "Test Loan",
        startDate: Date().addingTimeInterval(-60 * 24 * 3600), // 60 days ago
        annualInterestRate: 0.10, // 10%
        compoundingFrequency: .daily,
        status: .active
    )
    
    // Add initial capital
    let capitalTransaction = Transaction(
        date: loan.startDate,
        type: .capitalAddition(amount: 10000)
    )
    capitalTransaction.loan = loan
    loan.transactions.append(capitalTransaction)
    
    #expect(loan.currentPrincipal == 10000)
    
    // Calculate accrued interest (should be > 0 after 60 days)
    let accrued = loan.accruedInterest
    #expect(accrued > 0)
    
    // Total owed should be principal + interest (with small tolerance for floating point)
    let expectedTotal = loan.currentPrincipal + loan.accruedInterest
    let difference = abs(loan.totalOwed - expectedTotal)
    #expect(difference < 0.0001, "Total owed \(loan.totalOwed) should equal principal + interest \(expectedTotal), difference: \(difference)")
}

@Test func testPaymentTransactionEffects() async throws {
    let loan = Loan(
        borrowerName: "Test Loan",
        startDate: Date().addingTimeInterval(-30 * 24 * 3600),
        annualInterestRate: 0.08,
        compoundingFrequency: .daily
    )
    
    // Add capital
    let capital = Transaction(
        date: loan.startDate,
        type: .capitalAddition(amount: 5000)
    )
    capital.loan = loan
    loan.transactions.append(capital)
    
    // Make a payment
    let payment = Transaction(
        date: Date(),
        type: .payment(appliedToPrincipal: 1000, appliedToInterest: 50)
    )
    payment.loan = loan
    loan.transactions.append(payment)
    
    #expect(loan.currentPrincipal == 4000) // 5000 - 1000
}

// MARK: - Input Validation Tests

@Test func testDecimalParsing() async throws {
    // Valid decimal strings
    #expect(Decimal(string: "123.45") == 123.45)
    #expect(Decimal(string: "0") == 0)
    #expect(Decimal(string: "1000") == 1000)
    #expect(Decimal(string: "-123.45") == -123.45)
    
    // Invalid decimal strings
    #expect(Decimal(string: "") == nil)
    #expect(Decimal(string: "abc") == nil)
    #expect(Decimal(string: "$") == nil)
    #expect(Decimal(string: "12.34.56") != nil) // This actually parses to 12.34
    #expect(Decimal(string: "notanumber") == nil)
}

// MARK: - Edge Cases

@Test func testZeroPrincipalLoan() async throws {
    let loan = Loan(
        borrowerName: "Zero Loan",
        startDate: Date(),
        annualInterestRate: 0.05,
        compoundingFrequency: .daily
    )
    
    #expect(loan.currentPrincipal == 0)
    #expect(loan.accruedInterest == 0) // No principal, no interest
    #expect(loan.totalOwed == 0)
}

@Test func testZeroInterestRate() async throws {
    let loan = Loan(
        borrowerName: "Zero Interest Loan",
        startDate: Date().addingTimeInterval(-30 * 24 * 3600),
        annualInterestRate: 0,
        compoundingFrequency: .daily
    )
    
    // Add capital
    let capital = Transaction(
        date: loan.startDate,
        type: .capitalAddition(amount: 10000)
    )
    capital.loan = loan
    loan.transactions.append(capital)
    
    #expect(loan.currentPrincipal == 10000)
    #expect(loan.accruedInterest == 0) // Zero interest rate
    #expect(loan.totalOwed == 10000)
}

@Test func testNegativeInterestRate() async throws {
    // Test that negative interest rates are handled correctly
    let principal: Decimal = 10000
    let annualRate: Double = -0.02 // -2%
    
    let dailyInterest = LoanCalculator.calculateDailyInterest(
        principal: principal,
        annualRate: annualRate,
        compoundingFrequency: .daily
    )
    
    // Daily interest should be negative
    #expect(dailyInterest < 0, "Daily interest should be negative for negative rate, got \(dailyInterest)")
    
    // Test with a loan that has negative rate
    let loan = Loan(
        borrowerName: "Negative Interest Loan",
        startDate: Date().addingTimeInterval(-30 * 24 * 3600),
        annualInterestRate: -0.02,
        compoundingFrequency: .daily
    )
    
    // Even without transactions, the calculation should work
    let accrued = LoanCalculator.calculateAccruedInterest(for: loan, asOf: Date())
    #expect(accrued >= 0, "Accrued interest should be non-negative when no principal, got \(accrued)")
}

// MARK: - Compounding Frequency Tests

@Test func testCompoundingFrequencyEnum() async throws {
    #expect(CompoundingFrequency.daily == .daily)
    #expect(CompoundingFrequency.monthly == .monthly)
    #expect(CompoundingFrequency.annually == .annually)
    
    // Test that they are different
    #expect(CompoundingFrequency.daily != .monthly)
    #expect(CompoundingFrequency.monthly != .annually)
    #expect(CompoundingFrequency.annually != .daily)
}
