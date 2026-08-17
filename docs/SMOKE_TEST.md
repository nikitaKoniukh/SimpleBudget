# Manual smoke test checklist (SyncMonth UX)

## Auth & household
- [ ] Sign up / Google / Apple works
- [ ] Create household → lands with **no months** (friendly empty Home)
- [ ] Second user joins via invite and sees SyncMonth branding in share text
- [ ] Invite / CSV subjects say **SyncMonth** (not SimpleBudget)

## Navigation
- [ ] Bottom nav has **Home / Activity / Plan** (no Settings tab)
- [ ] Settings opens from gear on Home
- [ ] Language EN/RU toggle works in Settings

## Months
- [ ] **Create this month** opens full-screen flow (pick month → categories chips or copy)
- [ ] Copy from previous → categories + planned copied, actuals 0
- [ ] Select month from Home swap control
- [ ] **Start next month from this plan** in Settings

## Home
- [ ] Hero shows Remaining / Over with progress bar
- [ ] Income / Planned / Spent secondary row
- [ ] Category progress strips; tap opens category detail
- [ ] Plan > income shows calm warning chip
- [ ] FAB **Log** → Income / Expense sheet

## Activity
- [ ] Income entries list; tap to **edit / delete**
- [ ] Recent expenses (actual > 0)
- [ ] Empty state: Add first income
- [ ] Quick log from FAB

## Plan
- [ ] Category cards with type badge
- [ ] Manage categories / add defaults
- [ ] Category detail: stacked planned / spent / difference (not spreadsheet columns)

## Budget basics
- [ ] Line items Planned / Actual / Difference
- [ ] CSV export, language toggle
