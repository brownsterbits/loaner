import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// View for importing loan data from CSV files
@available(iOS 17.0, macOS 14.0, *)
struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var existingLoans: [Loan]

    @State private var showingFilePicker = false
    @State private var importPreview: CSVImporter.ImportPreview?
    @State private var showingPreview = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Import a loan from a CSV file exported by this app.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section("Import Format") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Loaner CSV exports only", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("The CSV file must match the format created by the Export feature.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Choose CSV File", systemImage: "doc.badge.plus")
                    }
                }

                if let preview = importPreview {
                    previewSection(preview)
                }
            }
            .navigationTitle("Import Loan")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if importPreview != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Import") {
                            performImport()
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Import Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    @ViewBuilder
    private func previewSection(_ preview: CSVImporter.ImportPreview) -> some View {
        Section("Preview") {
            LabeledContent("Borrower") {
                Text(preview.borrowerName)
                    .fontWeight(.semibold)
            }

            LabeledContent("Start Date") {
                Text(preview.startDate, format: .dateTime.month().day().year())
            }

            LabeledContent("Interest Rate") {
                Text(preview.interestRate * 100, format: .number.precision(.fractionLength(2)))
                    + Text("%")
            }

            LabeledContent("Transactions") {
                Text("\(preview.transactions.count)")
                    .fontWeight(.semibold)
            }
        }

        Section("Summary") {
            LabeledContent("Total Invested") {
                Text(preview.totalInvestments, format: .currency(code: "USD"))
                    .foregroundStyle(.blue)
            }

            LabeledContent("Total Payments") {
                Text(preview.totalPayments, format: .currency(code: "USD"))
                    .foregroundStyle(.green)
            }
        }

        Section {
            Text("Review the information above and tap Import to add this loan to your portfolio.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Unable to access the selected file"
                showingError = true
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            do {
                let preview = try CSVImporter.parseCSV(from: url)
                importPreview = preview
                #if DEBUG
                print("✅ CSV parsed successfully: \(preview.borrowerName), \(preview.transactions.count) transactions")
                #endif
            } catch let error as CSVImporter.ImportError {
                errorMessage = error.localizedDescription
                showingError = true
                #if DEBUG
                print("❌ Import error: \(error.localizedDescription)")
                #endif
            } catch {
                errorMessage = "Unable to read file: \(error.localizedDescription)"
                showingError = true
                #if DEBUG
                print("❌ File error: \(error.localizedDescription)")
                #endif
            }

        case .failure(let error):
            errorMessage = "File selection failed: \(error.localizedDescription)"
            showingError = true
            #if DEBUG
            print("❌ File picker error: \(error.localizedDescription)")
            #endif
        }
    }

    private func performImport() {
        guard let preview = importPreview else { return }

        // Check if loan with same name already exists
        if existingLoans.contains(where: { $0.borrowerName == preview.borrowerName }) {
            errorMessage = "A loan for \(preview.borrowerName) already exists. Please delete it first or rename the borrower in the CSV file."
            showingError = true
            return
        }

        // Create the loan
        let newLoan = CSVImporter.createLoan(from: preview)
        context.insert(newLoan)

        // Insert all transactions
        for transaction in newLoan.transactions {
            context.insert(transaction)
        }

        #if DEBUG
        print("✅ Loan imported successfully: \(newLoan.borrowerName)")
        #endif
        dismiss()
    }
}
