# Manual smoke test checklist (v2)

## Auth & household
- [ ] Sign up / Google / Apple works
- [ ] Create household → lands with **no months** (empty state)
- [ ] Second user joins via invite and sees the same empty/shared data

## Months
- [ ] Add month (empty) for current year/month
- [ ] Add categories, income, expenses
- [ ] Add another month with **Copy from previous** → categories + planned copied, actuals 0
- [ ] Select month from list; cannot open a month that was never created

## Categories
- [ ] Add / edit / delete category (expense, savings, debt + color)
- [ ] Deleting category removes its line items
- [ ] Empty category state prompts to add category

## Budget
- [ ] Income sources + multi amounts
- [ ] Line items Planned / Actual / Difference
- [ ] Overview, CSV export, language toggle
