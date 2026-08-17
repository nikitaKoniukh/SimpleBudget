# SyncMonth

Family monthly budget planner for iOS and Android. Shared household: everyone can
view and edit. Users create months and categories themselves (no auto-seed).

**Tagline:** Family monthly budget / Семейный месячный бюджет

## Stack

- Flutter (iOS / Android)
- Firebase Auth (email/password, Google, Apple on iOS)
- Cloud Firestore (household sync + offline cache)
- English / Russian UI toggle
- Currency: ₪ ILS
- App IDs: `com.yetzira.syncmonth`

## Product model

1. Create or join a **household** (all members can edit)
2. **Create month** (pick categories, or copy previous month’s plan — actuals reset)
3. **Home** — month health + category progress
4. **Activity** — income and spends / quick log
5. **Plan** — categories and line items
6. Invite partner via code; live sync

## Firebase

- Project: `simplebudget-family`
- After wiping old data, new households start with **no months**

### Auth setup

See previous README notes for Google SHA-1, Apple Sign In, and OAuth client IDs in
[`lib/config/oauth_config.dart`](lib/config/oauth_config.dart).

## Run

```bash
export PATH="$HOME/flutter/bin:$PATH"
flutter pub get
flutter run
```

See [`docs/SMOKE_TEST.md`](docs/SMOKE_TEST.md) for a manual checklist.
