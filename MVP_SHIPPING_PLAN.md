# Loaner MVP Shipping Plan
## Step-by-Step Guide to App Store Launch

**Target:** Ship v1.0 to App Store
**Timeline:** 7-10 days (10-15 hours total)
**Philosophy:** Simple, polished, professional

---

## Phase 1: Core Polish (Days 1-3)
**Goal:** Make app usable for first-time users
**Time:** 6-8 hours

### Step 1: Remove Compounding Frequency (Day 1 - 2 hours)
**Why:** Simplifies loan creation, removes 95% unused complexity

**Files to Modify:**
- `Models/Loan.swift`
- `Models/LoanCalculator.swift`
- `Views/AddLoanView.swift`

**Tasks:**
1. ✅ Remove `CompoundingFrequency` enum from Loan.swift
2. ✅ Remove `compoundingFrequency` property from Loan model
3. ✅ Update Loan initializer (remove parameter)
4. ✅ Update all `LoanCalculator` functions to remove `compoundingFrequency` parameter
5. ✅ Simplify calculations to only daily compounding
6. ✅ Remove compounding picker from AddLoanView
7. ✅ Test: Create loan, verify daily interest calculation works

**Acceptance Criteria:**
- [ ] App builds without errors
- [ ] Can create new loan without compounding option
- [ ] Daily interest calculates correctly
- [ ] Existing loans (if any) still work

**Code Changes:**
```swift
// Loan.swift - Remove this entirely:
public var compoundingFrequency: CompoundingFrequency

// Loan.swift - Remove enum:
public enum CompoundingFrequency { ... }

// LoanCalculator - Simplify to only:
static func calculateDailyInterest(principal: Decimal, annualRate: Double) -> Decimal {
    let dailyRate = Decimal(annualRate) / 365
    return principal * dailyRate
}

// AddLoanView - Remove this section:
Picker("Compounding", selection: $compoundingFrequency) { ... }
```

---

### Step 2: Remove Loan Status (Day 1 - 1 hour)
**Why:** Not used anywhere, dead code, adds no value

**Files to Modify:**
- `Models/Loan.swift`
- `Views/AddLoanView.swift`
- `Views/LoanListView.swift` (LoanRowView)

**Tasks:**
1. ✅ Remove `LoanStatus` enum from Loan.swift
2. ✅ Remove `status` property from Loan model
3. ✅ Update Loan initializer (remove status parameter)
4. ✅ Remove status icon display in LoanRowView
5. ✅ Remove status accessibility label
6. ✅ Test: View loan list, no status shown

**Acceptance Criteria:**
- [ ] App builds without errors
- [ ] Loan rows display cleanly without status icons
- [ ] All loans are implicitly "active"

**Code Changes:**
```swift
// Loan.swift - Remove:
public var status: LoanStatus
public enum LoanStatus { ... }

// LoanRowView - Remove:
Image(systemName: loan.status.icon)
    .foregroundStyle(statusColor)

// Remove statusColor computed property
```

---

### Step 3: Add Delete Confirmation Dialog (Day 1 - 30 minutes)
**Why:** Prevent accidental deletion of real financial data

**Files to Modify:**
- `Views/LoanListView.swift`

**Tasks:**
1. ✅ Add `@State` for confirmation dialog
2. ✅ Add `.confirmationDialog` modifier
3. ✅ Update `deleteLoans()` to show confirmation first
4. ✅ Test: Swipe to delete shows "Are you sure?" dialog

**Acceptance Criteria:**
- [ ] Swiping to delete shows confirmation dialog
- [ ] Dialog shows loan borrower name
- [ ] "Delete" button is red/destructive
- [ ] Cancel button works
- [ ] Delete button actually deletes

**Code to Add:**
```swift
// LoanListView - Add state:
@State private var loanToDelete: Loan?
@State private var showingDeleteConfirmation = false

// Update deleteLoans:
private func deleteLoans(at offsets: IndexSet) {
    guard let index = offsets.first else { return }
    loanToDelete = loans[index]
    showingDeleteConfirmation = true
}

// Add to body after .sheet modifiers:
.confirmationDialog(
    "Delete Loan?",
    isPresented: $showingDeleteConfirmation,
    presenting: loanToDelete
) { loan in
    Button("Delete '\(loan.borrowerName)'", role: .destructive) {
        context.delete(loan)
        loanToDelete = nil
    }
    Button("Cancel", role: .cancel) {
        loanToDelete = nil
    }
} message: { loan in
    Text("This loan and all \(loan.transactions.count) transaction(s) will be permanently deleted.")
}
```

---

### Step 4: Improve Input Validation (Day 2 - 1.5 hours)
**Why:** Prevent invalid data entry, show helpful error messages

**Files to Modify:**
- `Views/AddLoanView.swift`
- `Views/AddPaymentView.swift`
- `Views/AddCapitalView.swift`

**Tasks:**

**AddPaymentView:**
1. ✅ Validate payment date not before loan start
2. ✅ Validate payment date not in future
3. ✅ Show helpful error message

**AddCapitalView:**
1. ✅ Validate investment date not before loan start
2. ✅ Validate investment date not in future
3. ✅ Show helpful error message

**AddLoanView:**
1. ✅ Validate interest rate is reasonable (0.1% - 50%)
2. ✅ Improve error messages

**Acceptance Criteria:**
- [ ] Cannot log payment before loan starts
- [ ] Cannot log payment in future
- [ ] Cannot add investment before loan starts
- [ ] Cannot add investment in future
- [ ] Error messages are clear and helpful
- [ ] Save button disabled when invalid

**Code Changes:**
```swift
// AddPaymentView.swift - Update validationMessage:
private var validationMessage: String? {
    // ... existing checks ...

    if date < loan.startDate {
        return "Payment date cannot be before loan start date (\(loan.startDate.formatted(date: .abbreviated, time: .omitted)))"
    }

    if date > Date() {
        return "Payment date cannot be in the future"
    }

    return nil
}

// AddCapitalView.swift - Same pattern:
private var validationMessage: String? {
    // ... existing checks ...

    if date < loan.startDate {
        return "Investment date cannot be before loan start date (\(loan.startDate.formatted(date: .abbreviated, time: .omitted)))"
    }

    if date > Date() {
        return "Investment date cannot be in the future"
    }

    return nil
}

// AddLoanView.swift - Improve rate validation:
if let rate = Double(annualRate), rate < 0.001 {
    return "Interest rate seems too low (minimum 0.1%)"
}
if let rate = Double(annualRate), rate > 0.5 {
    return "Interest rate seems too high (maximum 50%)"
}
```

---

### Step 5: Add Contextual Help Tips (Day 2 - 1.5 hours)
**Why:** Explain finance terms to non-expert users

**Files to Modify:**
- `Views/AddPaymentView.swift`
- `Views/LoanDetailView.swift`
- `Views/ExportView.swift`

**Tasks:**
1. ✅ Add info button next to "Interest First" strategy
2. ✅ Add info button next to "Principal Only" strategy
3. ✅ Add info button next to "Accrued Interest" label
4. ✅ Add info button in Export view for tax terms
5. ✅ Create reusable HelpButton component

**Acceptance Criteria:**
- [ ] Info (i) icons appear next to confusing terms
- [ ] Tapping shows helpful explanation
- [ ] Explanations are in plain English
- [ ] Dismissible with tap outside

**Code to Add:**
```swift
// Create new file: Views/HelpButton.swift
struct HelpButton: View {
    let title: String
    let message: String
    @State private var showingHelp = false

    var body: some View {
        Button {
            showingHelp = true
        } label: {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .alert(title, isPresented: $showingHelp) {
            Button("Got It", role: .cancel) {}
        } message: {
            Text(message)
        }
    }
}

// AddPaymentView.swift - Add help buttons:
Picker("Strategy", selection: $paymentStrategy) {
    HStack {
        Text("Interest First")
        HelpButton(
            title: "Interest First",
            message: "Standard practice: pays accrued interest first, then remainder to principal. Your daily interest rate stays the same until principal is reduced."
        )
    }.tag(PaymentStrategy.interestFirst)

    HStack {
        Text("Principal Only")
        HelpButton(
            title: "Principal Only",
            message: "Aggressive paydown: entire payment reduces principal. Your daily interest rate drops immediately, saving money long-term."
        )
    }.tag(PaymentStrategy.principalOnly)
}

// LoanDetailView.swift - Add help to "Interest":
HStack {
    Text("Interest")
        .font(.caption)
        .foregroundStyle(.secondary)
    HelpButton(
        title: "Accrued Interest",
        message: "Interest that has built up since the last interest payment. This is what you're currently owed."
    )
}
```

---

### Step 6: Improve Empty State (Day 2 - 30 minutes)
**Why:** First impression matters, guide users to first action

**Files to Modify:**
- `Views/LoanListView.swift`

**Tasks:**
1. ✅ Improve empty state text
2. ✅ Add icon/illustration
3. ✅ Add "Try Sample Loan" button (placeholder for now)

**Acceptance Criteria:**
- [ ] Empty state explains what app does
- [ ] Clear call-to-action buttons
- [ ] Visually appealing with icon

**Code Changes:**
```swift
// LoanListView.swift - Update emptyState:
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

            Button("Try Sample Loan") {
                createSampleLoan()
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Create a sample loan to explore")
        }
    }
}
```

---

### Step 7: Create Sample Loan Functionality (Day 3 - 1.5 hours)
**Why:** Let users explore without entering real financial data

**Files to Modify:**
- `Views/LoanListView.swift`

**Tasks:**
1. ✅ Create `createSampleLoan()` function
2. ✅ Generate realistic sample data
3. ✅ Create 2-3 historical transactions
4. ✅ Add UserDefaults flag to prevent duplicates
5. ✅ Test: Tap "Try Sample Loan" creates demo loan

**Acceptance Criteria:**
- [ ] Creates loan named "Sample Company"
- [ ] Has realistic amounts and interest
- [ ] Shows 2-3 transactions with history
- [ ] Can only create one sample (prevents spam)
- [ ] Can be deleted like any other loan

**Code to Add:**
```swift
// LoanListView.swift - Add function:
private func createSampleLoan() {
    // Check if sample already exists
    if loans.contains(where: { $0.borrowerName == "Sample Company" }) {
        return
    }

    // Create sample loan (started 6 months ago)
    let startDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!

    let sampleLoan = Loan(
        borrowerName: "Sample Company",
        startDate: startDate,
        annualInterestRate: 0.08, // 8% APR
        notes: "This is a sample loan to help you explore the app. Feel free to delete it anytime."
    )

    // Initial investment
    let initialInvestment = Transaction(
        date: startDate,
        type: .capitalAddition(amount: 10000),
        notes: "Initial investment"
    )
    initialInvestment.loan = sampleLoan
    sampleLoan.transactions.append(initialInvestment)
    context.insert(initialInvestment)

    // Additional investment 3 months ago
    let additionalInvestmentDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
    let additionalInvestment = Transaction(
        date: additionalInvestmentDate,
        type: .capitalAddition(amount: 5000),
        notes: "Additional investment"
    )
    additionalInvestment.loan = sampleLoan
    sampleLoan.transactions.append(additionalInvestment)
    context.insert(additionalInvestment)

    // Payment 1 month ago
    let paymentDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    let payment = Transaction(
        date: paymentDate,
        type: .payment(appliedToPrincipal: 0, appliedToInterest: 200),
        notes: "Interest payment"
    )
    payment.loan = sampleLoan
    sampleLoan.transactions.append(payment)
    context.insert(payment)

    // Save
    context.insert(sampleLoan)
    try? context.save()
}
```

---

## Phase 2: Onboarding (Days 4-5)
**Goal:** Welcome first-time users, explain app purpose
**Time:** 3-4 hours

### Step 8: Create Onboarding Flow (Day 4 - 3 hours)
**Why:** Users need to understand what app does and how to use it

**Files to Create:**
- `Views/OnboardingView.swift`

**Files to Modify:**
- `ContentView.swift`
- Add UserDefaults check for first launch

**Tasks:**
1. ✅ Create OnboardingView with 3 screens
2. ✅ Screen 1: "Track What You're Owed"
3. ✅ Screen 2: "How It Works"
4. ✅ Screen 3: "Try It Out" (sample loan option)
5. ✅ Add PageTabViewStyle for swipe navigation
6. ✅ Add UserDefaults flag for first launch
7. ✅ Wrap ContentView to show onboarding once

**Acceptance Criteria:**
- [ ] Shows on first launch only
- [ ] 3 screens with clear messaging
- [ ] Can swipe between screens
- [ ] "Get Started" button dismisses and goes to main app
- [ ] Never shows again (unless app reinstalled)

**Code to Create:**
```swift
// Views/OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    let onCreateSampleLoan: () -> Void

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Welcome
            OnboardingPage(
                icon: "dollarsign.circle.fill",
                iconColor: .blue,
                title: "Track What You're Owed",
                subtitle: "Loaner helps you manage loans where you're the lender",
                features: [
                    "Daily compound interest calculation",
                    "Track payments and investments",
                    "Export data for tax reporting"
                ],
                showNextButton: true,
                nextAction: { currentPage = 1 }
            )
            .tag(0)

            // Page 2: How It Works
            OnboardingPage(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .green,
                title: "How It Works",
                subtitle: "Simple 3-step process",
                features: [
                    "Add a loan with borrower and interest rate",
                    "Log payments as they come in",
                    "See what's owed: principal + accrued interest"
                ],
                showNextButton: true,
                nextAction: { currentPage = 2 }
            )
            .tag(1)

            // Page 3: Get Started
            VStack(spacing: 32) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)

                VStack(spacing: 12) {
                    Text("Ready to Start?")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Want to explore first? We'll create a sample loan so you can see how it works.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    Button {
                        onCreateSampleLoan()
                        isPresented = false
                        markOnboardingComplete()
                    } label: {
                        Label("Try Sample Loan", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        isPresented = false
                        markOnboardingComplete()
                    } label: {
                        Text("Start Fresh")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 60)
            .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    private func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let features: [String]
    let showNextButton: Bool
    let nextAction: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(iconColor)

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            if showNextButton {
                Button("Next") {
                    nextAction()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 40)
            }
        }
    }
}

// ContentView.swift - Modify to show onboarding:
@available(iOS 17.0, macOS 14.0, *)
public struct ContentView: View {
    @State private var showingOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @Environment(\.modelContext) private var context

    public var body: some View {
        LoanListView()
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView(
                    isPresented: $showingOnboarding,
                    onCreateSampleLoan: createSampleLoan
                )
                .interactiveDismissDisabled() // Can't dismiss by swiping down
            }
    }

    private func createSampleLoan() {
        // Same implementation as in LoanListView
        // Or extract to shared function
    }

    public init() {}
}
```

---

## Phase 3: App Store Assets (Days 6-7)
**Goal:** Complete all App Store submission requirements
**Time:** 4-5 hours

### Step 9: Create App Icon (Day 6 - 2 hours)
**Why:** Required for App Store, represents your brand

**Tasks:**
1. ✅ Design or commission icon (1024×1024)
2. ✅ Use SF Symbols for inspiration (dollarsign.circle, percent, chart)
3. ✅ Export all required sizes
4. ✅ Add to Assets.xcassets

**Icon Ideas:**
- Dollar sign in a circle with percentage symbol
- Handshake with dollar sign
- Calculator with % symbol
- Simple, recognizable, works at small sizes

**Tools:**
- **DIY:** Use SF Symbols app + Affinity Designer/Sketch
- **Commission:** Fiverr ($20-50), 99designs ($299+)
- **Template:** IconKitchen, AppIconMaker

**Acceptance Criteria:**
- [ ] 1024×1024 PNG artwork
- [ ] All sizes generated (or use Xcode automatic sizing)
- [ ] Looks good at 60px and 1024px
- [ ] No transparency (App Store requirement)
- [ ] Matches app aesthetic

**Files to Modify:**
- `Loaner/Assets.xcassets/AppIcon.appiconset/`

---

### Step 10: Take Screenshots (Day 6 - 1 hour)
**Why:** Required for App Store listing

**Required Sizes:**
- iPhone 16 Pro Max (6.9")
- iPhone SE (5.5")

**Screenshots to Take:**
1. Empty state (with "Try Sample Loan")
2. Loan list with 2-3 loans
3. Loan detail view showing metrics
4. Payment entry with preview
5. Export view with tax summary

**Tasks:**
1. ✅ Run app with sample data
2. ✅ Screenshot each key screen
3. ✅ Use simulator frame (optional)
4. ✅ Add subtle text overlays (optional): "Track Daily Interest", "Preview Payment Impact", etc.

**Tools:**
- Simulator → File → New Screen Shot
- Or use Screenshot.rocks for frames/text

**Acceptance Criteria:**
- [ ] 5 screenshots minimum per size
- [ ] Clear, professional looking
- [ ] Shows key features
- [ ] No personal/sensitive data visible

---

### Step 11: Write App Store Copy (Day 7 - 2 hours)
**Why:** Required for submission, affects discoverability

**Tasks:**

#### 11.1: App Name
**Current:** "Loaner"
**Subtitle:** "Track What You're Owed"

#### 11.2: Description (Up to 4000 chars)
```
TRACK LOANS WHERE YOU'RE THE LENDER

Loaner is the simple, accurate way to track money you've lent to friends, family, or business partners.

NO SPREADSHEETS. NO COMPLEXITY. JUST RESULTS.

• Daily compound interest calculation
• Payment tracking (interest vs principal)
• Complete transaction history
• Tax reporting (export to CSV)
• Beautiful, simple interface

DESIGNED FOR PRIVATE LENDERS

Whether you're:
- Lending to a friend starting a business
- Managing family loans
- Tracking real estate investments
- Private lending as a side income

Loaner handles the math so you can focus on the relationship.

HOW IT WORKS

1. Add a loan: Borrower name, amount, interest rate
2. Log payments: Track what's paid back (interest or principal)
3. See what's owed: Principal + accrued interest

ACCURATE CALCULATIONS YOU CAN TRUST

• Decimal-precision math (no rounding errors)
• Daily compound interest matching your agreements
• Payment preview shows impact before you save
• Complete audit trail for your records

PRIVACY FIRST

• All data stored locally on your device
• No account required
• No ads, no tracking
• Your financial data stays private

PERFECT FOR TAX TIME

• Tracks lifetime interest paid (taxable income for you)
• Tracks principal received (non-taxable)
• Export to CSV for your accountant
• Complete transaction history

WHO IS THIS FOR?

Loaner is NOT for borrowers tracking what they owe. It's for LENDERS tracking what's owed TO them.

If you've ever:
- Lost track of how much a friend owes you
- Wondered if interest calculations are correct
- Needed records for tax reporting
- Used a messy spreadsheet for loan tracking

Loaner is for you.

GET STARTED IN MINUTES

• No signup or login required
• Try a sample loan to explore
• Create your first real loan in 60 seconds
• Track unlimited loans

SUPPORT

Questions? Contact: [your email]
Privacy Policy: [your URL]
```

#### 11.3: Keywords (100 characters max)
```
loan,lender,interest,tracking,private,calculator,payment,principal,tax,investment
```

#### 11.4: What's New (First version)
```
Welcome to Loaner 1.0!

• Track loans where you're the lender
• Daily compound interest calculation
• Payment tracking with real-time preview
• Export data for tax reporting
• Simple, private, accurate

Start tracking what you're owed today!
```

#### 11.5: Promotional Text (170 chars, updatable without new version)
```
Track money you've lent with accurate daily interest calculations. Simple. Private. Perfect for tax reporting. Try the sample loan to explore!
```

#### 11.6: Support URL
Create simple page with:
- FAQ
- Contact email
- How-to guide

#### 11.7: Privacy Policy
**Required by App Store**

Simple template:
```
Loaner Privacy Policy

Last Updated: [Date]

Data Collection:
Loaner does NOT collect, store, or transmit any personal data. All loan data is stored locally on your device.

We do not:
- Collect personal information
- Track your usage
- Show ads
- Sell data to third parties

Data Storage:
All loan data is stored in your device's local database (SwiftData). Data never leaves your device unless you explicitly export it.

Contact:
Questions about privacy? Email: [your email]
```

**Acceptance Criteria:**
- [✅] App description written (clear, compelling)
- [✅] Keywords selected (relevant, under 100 chars)
- [✅] Support URL created (docs/support.html)
- [✅] Privacy policy created (docs/privacy.html) - pending GitHub Pages deployment

---

## Phase 4: Testing & Bug Fixes (Days 8-9)
**Goal:** Ensure app works flawlessly on real devices
**Time:** 4-5 hours

### Step 12: Device Testing (Day 8 - 3 hours)
**Why:** Simulator doesn't catch everything, test on real hardware

**Test Scenarios:**

#### 12.1: Core Workflows
1. ✅ Launch app (first time) → See onboarding
2. ✅ Create sample loan → Verify data looks correct
3. ✅ Delete sample loan → Confirm dialog works
4. ✅ Create real loan → Enter your BMB data
5. ✅ Add payment → Verify preview matches expected
6. ✅ Add investment → Verify principal increases
7. ✅ Export loan → Check CSV file

#### 12.2: Edge Cases
1. ✅ Create loan with 0.5% interest
2. ✅ Create loan with 50% interest
3. ✅ Log payment larger than total owed
4. ✅ Try to enter negative amounts
5. ✅ Try to set payment date before loan start
6. ✅ Try to set payment date in future

#### 12.3: Data Persistence
1. ✅ Create loan, force quit app, reopen → Loan still there
2. ✅ Add payment, force quit app, reopen → Payment recorded
3. ✅ Delete loan, force quit app, reopen → Loan gone

#### 12.4: iOS Features
1. ✅ Test VoiceOver (basic accessibility)
2. ✅ Test Dark Mode (should work automatically)
3. ✅ Test Dynamic Type (text scaling)
4. ✅ Test landscape orientation
5. ✅ Test iPad (if supporting)

**Acceptance Criteria:**
- [ ] All core workflows work perfectly
- [ ] All edge cases handled gracefully
- [ ] Data persists across app restarts
- [ ] No crashes or freezes
- [ ] UI looks good in dark mode

---

### Step 13: Bug Fixes & Polish (Day 9 - 2 hours)
**Why:** Address any issues found during testing

**Common Issues to Watch For:**
- Text truncation on smaller screens
- Keyboard covering input fields
- Decimal formatting issues
- Date picker behavior
- Navigation bugs

**Tasks:**
1. ✅ Fix any bugs found in Step 12
2. ✅ Test fixes on device
3. ✅ Verify with your real BMB loan data

**Acceptance Criteria:**
- [ ] All bugs from testing are fixed
- [ ] App feels smooth and professional
- [ ] No known issues remaining

---

## Phase 5: App Store Submission (Day 10)
**Goal:** Submit to App Store for review
**Time:** 2-3 hours

### Step 14: Prepare App Store Connect (Day 10 - 1 hour)
**Why:** Required before you can upload binary

**Tasks:**
1. ✅ Create App Store Connect account (if needed)
2. ✅ Create new app listing
3. ✅ Upload app icon
4. ✅ Upload screenshots
5. ✅ Fill in all metadata (name, description, keywords)
6. ✅ Add support URL
7. ✅ Add privacy policy URL
8. ✅ Select category (Finance)
9. ✅ Select pricing (Free)
10. ✅ Answer export compliance questions

**Acceptance Criteria:**
- [ ] App listing is complete
- [ ] All required fields filled
- [ ] Screenshots uploaded
- [ ] Ready for binary upload

---

### Step 15: Build & Upload (Day 10 - 1 hour)
**Why:** Submit app binary to Apple

**Tasks:**
1. ✅ Archive app in Xcode
   - Product → Archive
   - Wait for build to complete (~5 min)
2. ✅ Validate archive
   - Organizer → Validate App
   - Fix any validation errors
3. ✅ Upload to App Store Connect
   - Organizer → Distribute App
   - Upload to App Store Connect
   - Wait for upload (~10 min)
4. ✅ Wait for processing (~30 min)
5. ✅ Select build in App Store Connect
6. ✅ Submit for review

**Acceptance Criteria:**
- [ ] Archive builds successfully
- [ ] Validation passes
- [ ] Upload completes
- [ ] Build appears in App Store Connect
- [ ] Submitted for review

---

### Step 16: App Review (Days 11-12)
**Why:** Apple reviews all apps before approval

**Timeline:**
- Typical: 24-48 hours
- Can be up to 5 days

**What Apple Checks:**
- App works as described
- No crashes or major bugs
- Follows App Store guidelines
- Privacy policy exists
- Age rating is accurate

**Possible Outcomes:**

#### If Approved:
- ✅ Congratulations! App goes live
- ✅ Share with friends/colleagues
- ✅ Monitor reviews and ratings
- ✅ Plan v1.1 based on feedback

#### If Rejected:
- 📝 Read rejection reason carefully
- 🔧 Fix the issue
- 📤 Resubmit with explanation
- ⏰ Wait another 24-48 hours

**Common Rejection Reasons:**
- Missing privacy policy
- App crashes during review
- Metadata doesn't match functionality
- Missing features mentioned in description

---

## Post-Launch Checklist

### Day of Launch
- [ ] Test downloading from App Store
- [ ] Verify app works when downloaded fresh
- [ ] Share with friends/family
- [ ] Post on social media (optional)
- [ ] Monitor App Store reviews

### Week 1
- [ ] Respond to user reviews
- [ ] Track usage/downloads (App Store Connect)
- [ ] Note common user requests
- [ ] Fix any critical bugs (hot fix)

### Month 1
- [ ] Analyze user feedback
- [ ] Plan v1.1 features based on requests
- [ ] Consider adding:
  - Payment templates (if users ask)
  - Portfolio summary (if users have many loans)
  - Rate changes over time (if users need it)

---

## Success Metrics

### v1.0 Goals
- [ ] Ship to App Store
- [ ] No critical bugs reported
- [ ] 10 downloads (friends/family)
- [ ] 4+ star average rating

### v1.1 Goals (Future)
- [ ] Add most-requested feature
- [ ] 100 downloads
- [ ] 10 reviews

### v2.0 Goals (Future)
- [ ] Premium features (if applicable)
- [ ] 1,000 downloads
- [ ] Featured in Finance category

---

## Risk Mitigation

### What Could Go Wrong?

**Risk:** App Store rejection
**Mitigation:** Follow guidelines carefully, test thoroughly

**Risk:** Data loss bug
**Mitigation:** Test persistence extensively, consider backup/export

**Risk:** Calculation errors
**Mitigation:** Verify with your real BMB loan data, matches spreadsheet

**Risk:** User confusion
**Mitigation:** Onboarding + help tips + sample loan

**Risk:** Bad reviews
**Mitigation:** Polish before launch, respond to feedback quickly

---

## Time Breakdown Summary

| Phase | Tasks | Time | Days |
|-------|-------|------|------|
| **Phase 1: Core Polish** | Simplify + validate + help | 6-8 hrs | 1-3 |
| **Phase 2: Onboarding** | Welcome flow | 3-4 hrs | 4-5 |
| **Phase 3: App Store Assets** | Icon + screenshots + copy | 4-5 hrs | 6-7 |
| **Phase 4: Testing** | Device testing + fixes | 4-5 hrs | 8-9 |
| **Phase 5: Submission** | Upload + submit | 2-3 hrs | 10 |
| **TOTAL** | | **19-25 hrs** | **10 days** |

---

## Daily Schedule (Suggested)

**Days 1-3:** Core Polish (2-3 hrs/day)
- Remove complexity
- Add validation
- Improve UX

**Days 4-5:** Onboarding (2 hrs/day)
- Create welcome flow
- Wire up sample loan

**Days 6-7:** Assets (2-3 hrs/day)
- Create icon
- Write copy
- Take screenshots

**Days 8-9:** Testing (2-3 hrs/day)
- Test on iPhone
- Fix bugs
- Verify with real data

**Day 10:** Ship It! (2-3 hrs)
- Upload to App Store
- Submit for review

**Days 11-12:** Wait for Apple Review
- Monitor App Store Connect
- Prepare for launch

---

## Final Pre-Flight Checklist

Before submitting to App Store, verify:

### Code
- [ ] App builds without warnings
- [ ] No crashes or freezes
- [ ] All features work on device

### Content
- [ ] App icon looks professional
- [ ] Screenshots are clear and accurate
- [ ] Description is compelling
- [ ] Privacy policy is published

### Testing
- [ ] Tested on real iPhone
- [ ] Tested with real data (BMB loan)
- [ ] All edge cases handled
- [ ] Onboarding shows on first launch

### Legal
- [ ] Privacy policy URL works
- [ ] Support URL works
- [ ] Terms accurate (if any)
- [ ] Age rating correct (4+)

### Polish
- [ ] Dark mode looks good
- [ ] Accessibility labels present
- [ ] Help tips are clear
- [ ] Confirmation dialogs work

---

## You're Ready When...

✅ You can hand your phone to a stranger
✅ They open the app
✅ They understand what it does (onboarding)
✅ They create a loan without asking for help
✅ They log a payment successfully
✅ They say "Oh, that's actually really useful!"

**That's when you ship.**

---

## Need Help?

**Stuck on a step?** Break it down smaller.
**Found a bug?** Write it down, fix in batch.
**Unsure about decision?** Ship the simpler version.
**Feeling overwhelmed?** Focus on just today's tasks.

**Remember:** Done is better than perfect. Ship v1.0, iterate to v1.1.

---

# Let's Build This! 🚀

**Next Step:** Start with Step 1 (Remove Compounding Frequency)
**Estimated Time:** 2 hours
**Goal:** Simpler loan creation, less code

Ready to begin?
