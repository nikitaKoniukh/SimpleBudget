# SimpleBudget

Family monthly budget planner for iOS and Android. Replaces a shared Google Sheets
workflow (income, color categories, planned vs actual) with Flutter + Firebase.

## Stack

- Flutter (iOS / Android)
- Firebase Auth (email/password)
- Cloud Firestore (household sync + offline cache)
- English / Russian UI toggle
- Currency: ₪ ILS

## Firebase project

- Project ID: `simplebudget-family`
- Console: https://console.firebase.google.com/project/simplebudget-family/overview

### One-time console setup

1. **Authentication** → Sign-in method → enable **Email/Password**  
   https://console.firebase.google.com/project/simplebudget-family/authentication/providers
2. Firestore database is already created (`europe-west1`) and rules are in `firestore.rules`.
3. Redeploy rules anytime:

```bash
firebase deploy --only firestore:rules --project=simplebudget-family
```

## Run

```bash
export PATH="$HOME/flutter/bin:$PATH"
flutter pub get
flutter run
```

## App flows

1. Sign up / sign in
2. Create household **or** join with invite code (Settings → copy code for partner)
3. Month hub: Income / Budget / Actual / Remaining + category cards
4. Income: multi-entry amounts per source
5. Category detail: Planned / Actual / Difference
6. Overview: overspent, savings (Set aside), duplicate next month from plan
7. Settings: language EN/RU, invite code, sign out

New months are seeded from the family sheet template (Home, Car, Shopping, Set aside, Visa, …).
