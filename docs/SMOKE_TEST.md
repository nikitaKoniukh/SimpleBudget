# Manual smoke test checklist

Use after `flutter run` on a simulator or device.

## Auth
- [ ] Email sign-up creates account and reaches household onboarding
- [ ] Email sign-in works for existing user
- [ ] Google Sign-In button appears (needs Firebase Google provider + SHA-1 / OAuth client IDs)
- [ ] Apple Sign-In button appears on iOS device/simulator with Sign in with Apple capability
- [ ] Cancelled Google/Apple flow does not show a scary error

## Household
- [ ] Create household seeds current month categories
- [ ] Settings shows invite code; Copy works
- [ ] Share invite opens system share sheet with code
- [ ] Second account can Join with invite code and sees same data live

## Month flows
- [ ] Month hub shows Income / Budget / Actual / Remaining
- [ ] Category type badges: Savings / Expense / Debt
- [ ] Add income entry; totals update
- [ ] Edit line item Planned/Actual; Difference colors correctly
- [ ] Overview lists overspent items; duplicate month creates next month with actuals = 0
- [ ] Export CSV shares a `.csv` file
- [ ] Language toggle EN ↔ RU updates labels
- [ ] Month chevrons show snackbar with month name
