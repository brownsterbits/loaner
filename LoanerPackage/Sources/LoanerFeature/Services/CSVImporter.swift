import Foundation

/// Imports loan data from CSV files in our export format
struct CSVImporter {
    enum ImportError: LocalizedError {
        case invalidFormat
        case missingHeader
        case invalidLoanInfo
        case invalidTransaction(line: Int, reason: String)
        case emptyFile

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "This file doesn't match the Loaner export format"
            case .missingHeader:
                return "CSV header row is missing or invalid"
            case .invalidLoanInfo:
                return "Unable to read loan information from file"
            case .invalidTransaction(let line, let reason):
                return "Invalid transaction on line \(line): \(reason)"
            case .emptyFile:
                return "The CSV file is empty"
            }
        }
    }

    struct ImportPreview {
        let borrowerName: String
        let startDate: Date
        let interestRate: Decimal
        let transactions: [Transaction]

        var totalInvestments: Decimal {
            transactions
                .filter { if case .capitalAddition = $0.type { return true } else { return false } }
                .reduce(0) { total, transaction in
                    if case .capitalAddition(let amount) = transaction.type {
                        return total + amount
                    }
                    return total
                }
        }

        var totalPayments: Decimal {
            transactions
                .filter { if case .payment = $0.type { return true } else { return false } }
                .reduce(0) { total, transaction in
                    if case .payment(let principal, let interest) = transaction.type {
                        return total + principal + interest
                    }
                    return total
                }
        }
    }

    /// Parse a CSV file and return an import preview
    static func parseCSV(from url: URL) throws -> ImportPreview {
        let content = try String(contentsOf: url, encoding: .utf8)
        return try parseCSV(content: content)
    }

    /// Parse CSV content string
    static func parseCSV(content: String) throws -> ImportPreview {
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard lines.count >= 5 else {
            throw ImportError.emptyFile
        }

        // Parse header: Line 1 - "Loan Export: [Name]"
        guard lines[0].hasPrefix("Loan Export: ") else {
            throw ImportError.invalidFormat
        }
        let borrowerName = String(lines[0].dropFirst("Loan Export: ".count))

        // Parse header: Line 2 - "Start Date: [Date]"
        guard lines[1].hasPrefix("Start Date: ") else {
            throw ImportError.invalidLoanInfo
        }
        let startDateString = String(lines[1].dropFirst("Start Date: ".count))
        guard let startDate = parseDate(startDateString) else {
            throw ImportError.invalidLoanInfo
        }

        // Parse header: Line 3 - "Interest Rate: [Rate]%"
        guard lines[2].hasPrefix("Interest Rate: ") else {
            throw ImportError.invalidLoanInfo
        }
        let rateString = String(lines[2].dropFirst("Interest Rate: ".count).dropLast())
        guard let rateDouble = Double(rateString), rateDouble > 0 else {
            throw ImportError.invalidLoanInfo
        }
        let interestRate = Decimal(rateDouble) / 100 // Convert percentage to decimal

        // Line 4 should be column headers
        guard lines[3] == "Date,Type,Amount,Principal Paid,Interest Paid,Notes" else {
            throw ImportError.missingHeader
        }

        // Parse transactions (starting from line 5)
        var transactions: [Transaction] = []
        for (index, line) in lines.dropFirst(4).enumerated() {
            let lineNumber = index + 5
            let transaction = try parseTransactionLine(line, lineNumber: lineNumber)
            transactions.append(transaction)
        }

        return ImportPreview(
            borrowerName: borrowerName,
            startDate: startDate,
            interestRate: interestRate,
            transactions: transactions
        )
    }

    private static func parseTransactionLine(_ line: String, lineNumber: Int) throws -> Transaction {
        #if DEBUG
        print("🔍 Parsing line \(lineNumber): \(line)")
        #endif

        // Split by comma, handling empty fields
        let components = line.split(separator: ",", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespaces) }

        #if DEBUG
        print("  Components: \(components)")
        #endif

        guard components.count >= 6 else {
            throw ImportError.invalidTransaction(line: lineNumber, reason: "Incorrect number of columns")
        }

        // Parse date
        let dateString = components[0]
        #if DEBUG
        print("  Parsing date: '\(dateString)'")
        #endif
        guard let date = parseDate(dateString) else {
            #if DEBUG
            print("  ❌ Failed to parse date: '\(dateString)'")
            #endif
            throw ImportError.invalidTransaction(line: lineNumber, reason: "Invalid date format: '\(dateString)'")
        }
        #if DEBUG
        print("  ✅ Date parsed: \(date)")
        #endif

        let type = components[1]
        let notes = components[5]

        // Parse based on transaction type
        switch type {
        case "Investment":
            guard let amount = parseDecimal(components[2]) else {
                throw ImportError.invalidTransaction(line: lineNumber, reason: "Invalid amount")
            }
            return Transaction(
                date: date,
                type: .capitalAddition(amount: amount),
                notes: notes
            )

        case "Payment":
            guard let totalAmount = parseDecimal(components[2]),
                  let principal = parseDecimal(components[3]),
                  let interest = parseDecimal(components[4]) else {
                throw ImportError.invalidTransaction(line: lineNumber, reason: "Invalid payment amounts")
            }

            // Verify math: total should equal principal + interest (with small tolerance for rounding)
            let calculatedTotal = principal + interest
            let difference = abs(NSDecimalNumber(decimal: totalAmount - calculatedTotal).doubleValue)
            guard difference < 0.01 else {
                throw ImportError.invalidTransaction(
                    line: lineNumber,
                    reason: "Payment total doesn't match principal + interest"
                )
            }

            return Transaction(
                date: date,
                type: .payment(appliedToPrincipal: principal, appliedToInterest: interest),
                notes: notes
            )

        default:
            throw ImportError.invalidTransaction(line: lineNumber, reason: "Unknown transaction type: \(type)")
        }
    }

    private static func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // Use fixed locale for reliable parsing
        formatter.timeStyle = .none

        // Try various date formats that match our export
        let formats = [
            "MMM d, yyyy",   // Jan 26, 2015
            "MMM dd, yyyy",  // Jan 26, 2015
            "MMM d,yyyy",    // Jan 26,2015 (no space after comma)
            "MMM dd,yyyy",   // Jan 26,2015
            "M/d/yyyy",      // 1/26/2015
            "MM/dd/yyyy",    // 01/26/2015
            "yyyy-MM-dd"     // 2015-01-26
        ]

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }

        // Try with dateStyle as fallback
        formatter.dateStyle = .medium
        formatter.locale = nil // Use system locale
        if let date = formatter.date(from: string) {
            return date
        }

        return nil
    }

    private static func parseDecimal(_ string: String) -> Decimal? {
        // Remove any whitespace
        let cleaned = string.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }

        // Try to parse as Decimal
        return Decimal(string: cleaned)
    }

    /// Create a Loan object from import preview
    static func createLoan(from preview: ImportPreview) -> Loan {
        // Convert Decimal interest rate to Double for Loan model
        let interestRateDouble = NSDecimalNumber(decimal: preview.interestRate).doubleValue

        let loan = Loan(
            borrowerName: preview.borrowerName,
            startDate: preview.startDate,
            annualInterestRate: interestRateDouble
        )

        // Set up bidirectional relationship for SwiftData
        for transaction in preview.transactions {
            transaction.loan = loan
            loan.transactions.append(transaction)
        }

        return loan
    }
}
