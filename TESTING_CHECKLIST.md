# Loaner v1.0 Testing Checklist

Quick reference for manual device testing before App Store submission.

---

## Pre-Testing Setup

- [ ] Delete app from device (resets onboarding flag and database)
- [ ] Rebuild from Xcode
- [ ] Install on device
- [ ] Test on at least 2 devices: small (SE) + large (Pro Max)

---

## Priority Tests (Must Pass)

### 1. First Launch & Onboarding ✅
- [ ] Onboarding appears automatically on first launch
- [ ] Shows 3 features with icons
- [ ] "Get Started" button dismisses onboarding
- [ ] Onboarding never appears again after dismissal
- [ ] Empty state appears after onboarding

### 2. Empty State
- [ ] Shows "No Loans Yet" with value proposition
- [ ] "Add Your First Loan" button works
- [ ] "Try Sample Loan" button works

### 3. Sample Loan
- [ ] Creates loan named "Sample: Alex Johnson"
- [ ] Shows $10,000 initial + $2,500 additional capital
- [ ] Shows 1 payment transaction
- [ ] Daily interest calculates correctly
- [ ] Total owed = principal + accrued interest
- [ ] Can tap loan to see detail view

### 4. Create Real Loan
- [ ] Tap "+" button in toolbar
- [ ] Enter borrower name (required validation works)
- [ ] Select start date (future dates blocked)
- [ ] Enter amount (negative/zero blocked)
- [ ] Enter interest rate (0.1% - 50% enforced)
- [ ] Optional notes field works
- [ ] "Add" button disabled until valid
- [ ] Loan appears in list after creation

### 5. Loan Detail View
- [ ] Shows loan summary card with correct totals
- [ ] Transaction history appears
- [ ] "Add Payment" button works
- [ ] "Add Capital" button works
- [ ] "Export" button works
- [ ] Back navigation works

### 6. Log Payment - Interest First
- [ ] Select payment date (validation: not before loan start, not in future)
- [ ] Enter payment amount
- [ ] Select "Interest First" strategy
- [ ] Preview shows correct allocation
- [ ] Preview shows before/after balances
- [ ] "Save" button works
- [ ] Transaction appears in history
- [ ] Totals update correctly

### 7. Log Payment - Principal Only
- [ ] Select "Principal Only" strategy
- [ ] Preview shows entire amount to principal
- [ ] Interest balance doesn't change in preview
- [ ] Daily interest amount decreases
- [ ] Save works correctly

### 8. Log Payment - Custom Split
- [ ] Select "Custom Split" strategy
- [ ] Enter custom principal amount
- [ ] Enter custom interest amount
- [ ] Validation: must equal total payment
- [ ] Preview updates correctly
- [ ] Save works correctly

### 9. Add Capital
- [ ] Select date (validation: not before loan start, not in future)
- [ ] Enter amount
- [ ] Impact preview shows:
  - Current principal → New principal
  - Current daily interest → New daily interest
  - Helpful text about interest increase
- [ ] Save works
- [ ] Transaction appears with "Capital Addition" type

### 10. Delete Loan
- [ ] Swipe left on loan in list
- [ ] Tap "Delete"
- [ ] Confirmation dialog appears
- [ ] Shows borrower name and transaction count
- [ ] "Cancel" works (loan remains)
- [ ] "Delete" works (loan removed)

### 11. Export to CSV
- [ ] Tap "Export" in loan detail
- [ ] Review screen shows summary
- [ ] Tap "Export CSV"
- [ ] Share sheet appears
- [ ] Save to Files works
- [ ] Open file in Numbers/Excel
- [ ] Verify columns: Date, Type, Amount, Principal, Interest, Notes

### 12. Help Button
- [ ] Tap help button on "Apply To" in payment screen
- [ ] Alert appears with strategy explanations
- [ ] "Got It" dismisses alert
- [ ] Re-tappable (doesn't break)

---

## Edge Cases (Should Handle Gracefully)

### Input Validation
- [ ] Try creating loan with empty name → blocked
- [ ] Try 0% interest rate → warning appears
- [ ] Try 100% interest rate → warning appears
- [ ] Try negative amount → blocked
- [ ] Try payment before loan start → blocked
- [ ] Try payment in future → blocked
- [ ] Try custom split that doesn't add up → blocked

### Date Handling
- [ ] Create loan today, log payment today → works
- [ ] Create loan 1 year ago → interest accrues correctly
- [ ] Add payment on exact loan start date → works
- [ ] Add capital after payment → calculations correct

### Large Numbers
- [ ] Loan amount $1,000,000 → displays correctly
- [ ] Payment amount $500,000 → works
- [ ] Interest rate 50% (max) → calculates correctly
- [ ] Daily interest over $100 → displays correctly

### Empty/Zero States
- [ ] Loan with no payments → shows only capital transaction
- [ ] Payment fully pays interest → interest becomes $0.00
- [ ] Payment reduces principal to $0 → can still add capital

---

## UI/UX Tests

### Dark Mode
- [ ] Switch iOS to Dark Mode (Settings → Display & Brightness)
- [ ] Open app
- [ ] All screens look good in dark mode
- [ ] Text is readable
- [ ] Colors contrast properly
- [ ] No white boxes or awkward inversions

### Accessibility (VoiceOver)
- [ ] Enable VoiceOver (Settings → Accessibility → VoiceOver)
- [ ] Navigate to each screen
- [ ] All buttons have labels
- [ ] All inputs have labels
- [ ] Loan amounts are spoken correctly
- [ ] Can navigate and use the app entirely with VoiceOver

### Dynamic Type
- [ ] Change text size (Settings → Display & Brightness → Text Size)
- [ ] Test at smallest size → text fits
- [ ] Test at largest size → text doesn't truncate awkwardly
- [ ] All screens remain usable

### Rotation (if supporting landscape)
- [ ] Rotate device
- [ ] All screens adapt correctly
- [ ] No content cut off
- [ ] Navigation still works

### iPad (if supporting iPad)
- [ ] App looks good on iPad
- [ ] Layouts use available space well
- [ ] Navigation works (split view or stack)
- [ ] All features work identically

---

## Performance & Stability

### App Launch
- [ ] Cold launch (force quit, reopen) → fast (<2 seconds)
- [ ] Onboarding shows on first launch only
- [ ] Loan list loads quickly with 10 loans
- [ ] No crashes on launch

### Memory
- [ ] Create 20 loans → no slowdown
- [ ] Navigate between screens repeatedly → no crashes
- [ ] Background and foreground app → state preserved

### Data Persistence
- [ ] Create loan, force quit app, reopen → loan still there
- [ ] Log payment, force quit app, reopen → payment still there
- [ ] All data persists across launches

### Network (N/A for v1.0)
- This app has no network features, so no network tests needed

---

## Regression Tests (If Bugs Were Fixed)

### Onboarding Bug Fix (Nov 13)
- [x] "Get Started" button dismisses onboarding
- [x] hasSeenOnboarding flag saves correctly
- [x] Onboarding never reappears after dismissal

---

## Known Non-Issues

### CoreData Logs on First Launch
**Expected:** Scary-looking logs about missing files on very first launch
**Why:** SwiftData creates database directory structure
**Evidence:** Logs end with "Recovery attempt was successful!"
**Action:** Ignore - this is normal iOS behavior

---

## Bug Template

If you find a bug, document it like this:

```markdown
### Bug: [Short Description]
**Severity:** Critical / High / Medium / Low
**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Device:** [iPhone 16 Pro / iPad / etc.]
**iOS Version:** [18.4 / etc.]
**App Version:** 1.0

**Screenshots:** [If applicable]

**Workaround:** [If one exists]
```

Save bugs to `BUGS.md` in project root.

---

## Testing Sign-Off

Once all priority tests pass:

- [ ] Tested on iPhone SE (small screen)
- [ ] Tested on iPhone 16 Pro Max (large screen)
- [ ] Tested on iPad (if supporting)
- [ ] Tested in Dark Mode
- [ ] Tested with VoiceOver
- [ ] Tested with Dynamic Type (large)
- [ ] All priority tests passing
- [ ] All edge cases handled
- [ ] No critical or high bugs
- [ ] Ready for App Store submission

**Tested By:** _______________
**Date:** _______________
**Build Number:** _______________

---

## Next Steps After Testing

1. Document any bugs in `BUGS.md`
2. Fix critical/high bugs before submission
3. If all tests pass, proceed to App Store asset creation
4. See `MVP_SHIPPING_PLAN.md` Steps 11-18 for submission process

---

**Last Updated:** November 13, 2025
**Version:** 1.0 (Build 1)
