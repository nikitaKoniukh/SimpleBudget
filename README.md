# SimpleBudget

Family monthly budget planner for iOS and Android. Replaces a shared Google Sheets
workflow (income, color categories, planned vs actual) with Flutter + Firebase.

## Stack

- Flutter (iOS / Android)
- Firebase Auth (email/password, Google, Apple on iOS)
- Cloud Firestore (household sync + offline cache)
- English / Russian UI toggle
- Currency: ₪ ILS

## Firebase project

- Project ID: `simplebudget-family`
- Console: https://console.firebase.google.com/project/simplebudget-family/overview

### Auth setup

1. **Email/Password** — enable in Authentication → Sign-in method (done if you already enabled it).
2. **Google**
   - Enable Google provider in Firebase Console.
   - Android: add your debug/release **SHA-1** under Project settings → Your apps → Android app, then re-download `google-services.json`.
   - iOS: re-download `GoogleService-Info.plist` (needs `CLIENT_ID` + `REVERSED_CLIENT_ID`).
   - Put `CLIENT_ID` / web client ID into [`lib/config/oauth_config.dart`](lib/config/oauth_config.dart).
   - Add `REVERSED_CLIENT_ID` as a URL scheme in `ios/Runner/Info.plist` (`CFBundleURLTypes`).
3. **Apple** (iOS)
   - Bundle ID is `com.yetzira.simplebudget` (same as Android applicationId).
   - In Apple Developer, create/update App ID with that bundle ID and enable **Sign In with Apple**.
   - Enable Apple provider in Firebase Console.
   - Xcode capability **Sign in with Apple** is wired via `ios/Runner/Runner.entitlements`.
   - Re-add your Android **SHA-1** on the new Android app (`com.yetzira.simplebudget`) in Firebase Project settings.

4. Firestore rules: `firebase deploy --only firestore:rules --project=simplebudget-family`

## Run

```bash
export PATH="$HOME/flutter/bin:$PATH"
flutter pub get
flutter run
```

Manual checklist: [docs/SMOKE_TEST.md](docs/SMOKE_TEST.md)

## App flows

1. Sign up / sign in (email, Google, or Apple on iOS)
2. Create household **or** join with invite code (Settings → copy or share invite)
3. Month hub: Income / Budget / Actual / Remaining + category cards with type badges
4. Income: multi-entry amounts per source
5. Category detail: Planned / Actual / Difference
6. Overview: overspent, savings (Set aside), duplicate next month, export CSV
7. Settings: language EN/RU, invite share, CSV export, sign out

New months are seeded from the family sheet template (Home, Car, Shopping, Set aside, Visa, …).
