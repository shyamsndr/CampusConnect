import {initializeApp, cert} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import * as fs from "fs";
import * as path from "path";

const serviceAccountPath = path.join(__dirname, "../../../serviceAccountKey.json");

if (process.env.FUNCTIONS_EMULATOR === "true" && fs.existsSync(serviceAccountPath)) {
  console.log("Initializing Firebase Admin with Service Account (Real FCM enabled)");
  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8"));
  initializeApp({
    credential: cert(serviceAccount),
  });
} else {
  initializeApp();
}

export const adminAuth = getAuth();
export const adminDb = getFirestore();
export const adminMessaging = getMessaging();
