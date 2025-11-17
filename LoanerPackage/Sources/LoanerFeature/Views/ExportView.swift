import SwiftUI
import UniformTypeIdentifiers

/// View for exporting loan data
@available(iOS 17.0, macOS 14.0, *)
struct ExportView: View {
    let loan: Loan

    @Environment(\.dismiss) private var dismiss
    @State private var exportURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Export all loan data including transactions to a CSV file for record keeping or tax purposes.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section("Tax Summary") {
                    LabeledContent("Interest Paid (Taxable)") {
                        Text(loan.lifetimeInterestPaid, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    }

                    LabeledContent("Principal Received") {
                        Text(loan.lifetimePrincipalPaid, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }

                    LabeledContent("Total Invested") {
                        Text(loan.totalInvested, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Outstanding Principal") {
                        Text(loan.currentPrincipal, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        exportCSV()
                    } label: {
                        Label("Export to CSV", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Export Data")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            #if os(iOS)
            .sheet(item: $exportURL) { url in
                let _ = print("📋 Sheet rendering with URL: \(url.path)")
                ShareSheet(items: [url])
                    .presentationDetents([.medium, .large])
            }
            #endif
            .alert("Export Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func exportCSV() {
        let csv = generateCSV()

        // Sanitize borrower name for filename (remove invalid characters)
        let sanitizedName = loan.borrowerName
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .trimmingCharacters(in: .whitespaces)

        // Use ISO8601 date format (YYYY-MM-DD) to avoid slashes in filename
        let dateFormatter = Date.FormatStyle()
            .year(.defaultDigits)
            .month(.twoDigits)
            .day(.twoDigits)
        let dateString = Date.now.formatted(dateFormatter).replacingOccurrences(of: "/", with: "-")
        let fileName = "\(sanitizedName)_Export_\(dateString).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        #if DEBUG
        print("📁 Attempting to export to: \(tempURL.path)")
        print("📄 CSV content length: \(csv.count) characters")
        #endif

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)

            #if DEBUG
            print("✅ File written successfully")
            #endif

            // Verify the file exists before showing share sheet
            guard FileManager.default.fileExists(atPath: tempURL.path) else {
                #if DEBUG
                print("❌ File does not exist after write")
                #endif
                errorMessage = "Failed to create export file"
                showingError = true
                return
            }

            #if DEBUG
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: tempURL.path)[.size] as? Int) ?? 0
            print("✅ File exists at path, size: \(fileSize)")
            #endif

            #if os(iOS)
            // Setting exportURL will automatically trigger the sheet to show
            exportURL = tempURL

            #if DEBUG
            print("✅ exportURL set to: \(exportURL?.path ?? "nil")")
            #endif
            #else
            // On macOS, open save panel
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.commaSeparatedText]
            savePanel.nameFieldStringValue = fileName
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try csv.write(to: url, atomically: true, encoding: .utf8)
                        dismiss()
                    } catch {
                        errorMessage = "Failed to save file: \(error.localizedDescription)"
                        showingError = true
                    }
                }
            }
            #endif
        } catch {
            errorMessage = "Failed to create export: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func generateCSV() -> String {
        var csv = "Loan Export: \(loan.borrowerName)\n"

        // Use ISO8601 date format (YYYY-MM-DD) to avoid commas in dates
        let dateFormatter = Date.FormatStyle()
            .year(.defaultDigits)
            .month(.twoDigits)
            .day(.twoDigits)
        let startDateString = loan.startDate.formatted(dateFormatter).replacingOccurrences(of: "/", with: "-")

        csv += "Start Date: \(startDateString)\n"
        csv += "Interest Rate: \(String(format: "%.2f", loan.annualInterestRate * 100))%\n\n"

        csv += "Date,Type,Amount,Principal Paid,Interest Paid,Notes\n"

        for transaction in loan.sortedTransactions.reversed() {
            let dateString = transaction.date.formatted(dateFormatter).replacingOccurrences(of: "/", with: "-")
            let notes = transaction.notes.trimmingCharacters(in: .whitespacesAndNewlines)

            switch transaction.type {
            case .capitalAddition(let amount):
                let formattedAmount = String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue)
                csv += "\(dateString),Investment,\(formattedAmount),,,\(notes)\n"
            case .payment(let principal, let interest):
                let total = principal + interest
                let formattedTotal = String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
                let formattedPrincipal = String(format: "%.2f", NSDecimalNumber(decimal: principal).doubleValue)
                let formattedInterest = String(format: "%.2f", NSDecimalNumber(decimal: interest).doubleValue)
                csv += "\(dateString),Payment,\(formattedTotal),\(formattedPrincipal),\(formattedInterest),\(notes)\n"
            }
        }

        return csv
    }
}

#if os(iOS)
/// UIKit share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Make URL Identifiable so it can be used with .sheet(item:)
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
#endif
