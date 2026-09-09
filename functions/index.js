const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

setGlobalOptions({ region: "us-central1" });
initializeApp();

async function setHouseholdClaims(uid, householdIds) {
  const ids = Array.isArray(householdIds) ? householdIds : [];
  await getAuth().setCustomUserClaims(uid, { householdIds: ids });
}

exports.syncMembershipClaims = onDocumentWritten(
  "users/{uid}",
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;
    await setHouseholdClaims(event.params.uid, after.data()?.householdIds);
  },
);

exports.refreshMembershipClaims = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;
  const snap = await getFirestore().doc(`users/${uid}`).get();
  const ids = snap.data()?.householdIds ?? [];
  await setHouseholdClaims(uid, ids);
  return { householdIds: ids };
});
