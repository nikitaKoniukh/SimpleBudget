# SyncMonth

Family monthly budget planner for iOS and Android. Replaces a shared Google Sheets
workflow (income, color categories, planned vs actual) with Flutter + Firebase.

## Identity

| | |
|---|---|
| Display name | **SyncMonth** |
| Dart package | `sync_month` |
| Android `applicationId` | `com.yetzira.syncmonth` |
| iOS bundle ID | `com.yetzira.syncmonth` |
| Firebase project | `simplebudget-family` (unchanged) |

## Stack

- Flutter (iOS / Android)
- Firebase Auth (email/password, Google, Apple on iOS)
- Cloud Firestore (household sync + offline cache)
- English / Russian UI toggle
- Currency: ₪ ILS

## Firebase project

- Project ID: `simplebudget-family`
- Console: https://console.firebase.google.com/project/simplebudget-family/overview

### SyncMonth Firebase apps (done)

Registered on project `simplebudget-family`:

| Platform | Package / Bundle ID | App ID |
|----------|---------------------|--------|
| Android | `com.yetzira.syncmonth` | `1:339787672116:android:2496b3e3b1ad3ff30a7861` |
| iOS | `com.yetzira.syncmonth` | `1:339787672116:ios:2f314c0946fbae380a7861` |

Config files are wired (`google-services.json`, `GoogleService-Info.plist`, `lib/firebase_options.dart`, OAuth URL scheme).

Still required for Google Sign-In on Android:

1. Add debug/release **SHA-1** on the SyncMonth Android app in Firebase Project settings, then re-download `google-services.json` if OAuth clients change.
2. Apple Developer: App ID `com.yetzira.syncmonth` with **Sign In with Apple**.

Old `com.yetzira.simplebudget` apps can be removed from Firebase when you no longer need them.

To regenerate configs later:

```bash
flutterfire configure --project=simplebudget-family \
  --platforms=android,ios \
  --android-package-name=com.yetzira.syncmonth \
  --ios-bundle-id=com.yetzira.syncmonth
```

### Auth setup

1. **Email/Password** — enable in Authentication → Sign-in method.
2. **Google** — enable provider; complete SHA-1 + OAuth steps above.
3. **Apple** (iOS) — App ID `com.yetzira.syncmonth` + capability in `ios/Runner/Runner.entitlements`.
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
