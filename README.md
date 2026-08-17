# SimpleBudget

Family monthly budget planner for iOS and Android. Shared household: everyone can
view and edit. Users create months and categories themselves (no auto-seed).

## Stack

- Flutter (iOS / Android)
- Firebase Auth (email/password, Google, Apple on iOS)
- Cloud Firestore (household sync + offline cache)
- English / Russian UI toggle
- Currency: ₪ ILS
- App IDs: `com.yetzira.simplebudget`

## v2 product model

1. Create or join a **household** (all members can edit)
2. **Add month** (empty, or copy previous month’s plan — actuals reset)
3. **Add categories** yourself (expense / savings / debt + color)
4. Add **income** sources/amounts and **expense** line items (planned / actual)
5. Invite partner via code; live sync

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

Manual checklist: [docs/SMOKE_TEST.md](docs/SMOKE_TEST.md)
