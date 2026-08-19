# Manual smoke test checklist (SyncMonth UX)

## Auth & household
- [ ] Sign up / Google / Apple works
- [ ] Create household → lands with **no months** (friendly empty Home)
- [ ] Second user joins via invite and sees SyncMonth branding in share text
- [ ] Invite / CSV subjects say **SyncMonth** (not SimpleBudget)
- [ ] Non-owner can **Leave household** without deleting the account
- [ ] Members sheet shows names; owner can set editor vs log-only

## Navigation
- [ ] Bottom nav has **Home / Activity / Set aside** (no Settings tab)
- [ ] Settings opens from gear on Home
- [ ] Language EN / RU / Hebrew toggle works in Settings
- [ ] Reports and Recurring bills open from Settings

## Months
- [ ] **Create this month** opens full-screen flow (pick month)
- [ ] If another month exists: copy source, empty month, leftover rollover
- [ ] Copy from previous → categories + planned copied, actuals 0 (unless rollover)
- [ ] Select month from Home swap control
- [ ] **Start next month from this plan** in Settings

## Home
- [ ] Hero shows Remaining / Over from **income − spends** (deposits do not count as spend)
- [ ] Set aside this month is a separate line when deposits exist
- [ ] Watchlist chips when a category is at/over 80% of plan
- [ ] Upcoming recurring bills for the rest of this month
- [ ] Income / Planned / Spent secondary row
- [ ] Category progress strips
- [ ] Plan > income shows calm warning chip
- [ ] FAB **Log** → Income / Expense / Set aside
- [ ] Edit plan is disabled for log-only members

## Activity
- [ ] Search and category filters
- [ ] Empty state: add first income **or** first expense
- [ ] Income and expenses show **who logged**
- [ ] Deposits labeled; split spends labeled
- [ ] Tap to edit / delete

## Set aside
- [ ] Pots with optional target and target date
- [ ] Log deposit does not reduce Home remaining

## Budget basics
- [ ] Split a new spend across two line items
- [ ] CSV export, language toggle
