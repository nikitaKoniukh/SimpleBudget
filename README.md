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

### Register SyncMonth apps (required after rename)

The package/bundle ID changed from `com.yetzira.simplebudget` → `com.yetzira.syncmonth`.
Firebase still uses project `simplebudget-family`, but you must register **new** Android/iOS apps:

1. Firebase Console → Project settings → Your apps → **Add app**
   - Android package name: `com.yetzira.syncmonth`
   - iOS bundle ID: `com.yetzira.syncmonth`
2. Download fresh `google-services.json` → `android/app/google-services.json`
3. Download fresh `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`
4. Run FlutterFire (recommended):

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=simplebudget-family
```

   This refreshes `lib/firebase_options.dart` and `firebase.json` with the new app IDs.
5. Android: add debug/release **SHA-1** on the new Android app, then re-download `google-services.json` if OAuth clients change.
6. Update [`lib/config/oauth_config.dart`](lib/config/oauth_config.dart) from the new plist (`CLIENT_ID`, web client ID).
7. Set `REVERSED_CLIENT_ID` as a URL scheme in `ios/Runner/Info.plist` (`CFBundleURLTypes`).
8. Apple Developer: create/update App ID `com.yetzira.syncmonth` with **Sign In with Apple**, then enable Apple provider in Firebase.

You can remove the old `com.yetzira.simplebudget` apps from Firebase once the new ones work.

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
