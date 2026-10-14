import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {FieldValue} from "firebase-admin/firestore";

import {adminDb, adminMessaging} from "./config/firebase";
import {
  checkAuthEmailExists,
  createAuthUser,
  deleteAuthUser,
} from "./services/auth_service";
import {sendWelcomeEmail} from "./services/email_service";
import {
  checkEmailExistsInFirestore,
  checkMemberCodeExists,
  createUserProfile,
  deleteUserProfile,
  getUserProfile,
} from "./services/user_service";
import { processNewComplaint, calculatePriorityScore } from "./services/complaint_service";
import {generateTemporaryPassword} from "./utils/password_generator";
import {validateEmailDomainDns, validateUserData} from "./utils/validators";

interface CreateUserRequest {
  memberCode: string;
  name: string;
  email: string;
  role: "Student" | "Staff";
  department: string;
  phone: string;
}

export const createUser = onCall(async (request) => {
  // ── 1. Caller must be authenticated ────────────────────────────────────────
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You are not authorized to add users.",
      {code: "UNAUTHORIZED"},
    );
  }

  const callerUid = request.auth.uid;

  // ── 2. Caller must be an Admin (verified via Firestore, never trusted from client) ──
  const callerDoc = await adminDb.collection("USERS").doc(callerUid).get();

  if (!callerDoc.exists || callerDoc.data()?.role !== "Admin") {
    throw new HttpsError(
      "permission-denied",
      "You are not authorized to add users.",
      {code: "FORBIDDEN"},
    );
  }

  if (callerDoc.data()?.status !== "Active") {
    throw new HttpsError(
      "permission-denied",
      "Your admin account is not active.",
      {code: "ACCOUNT_NOT_ACTIVE"},
    );
  }

  // ── 3. Validate and normalise input data ────────────────────────────────────
  const raw = request.data as Partial<CreateUserRequest>;

  const memberCode = (raw.memberCode ?? "").trim().toUpperCase();
  const name = (raw.name ?? "").trim();
  const email = (raw.email ?? "").trim().toLowerCase();
  const role = (raw.role ?? "") as string;
  const department = (raw.department ?? "").trim();
  const phone = (raw.phone ?? "").trim();

  const validationError = validateUserData({
    memberCode,
    name,
    email,
    role,
    department,
    phone,
  });

  if (validationError) {
    throw new HttpsError("invalid-argument", validationError, {
      code: "INVALID_DATA",
    });
  }

  // ── 3b. Validate mail-routing DNS records where feasible ───────────────────
  const dnsError = await validateEmailDomainDns(email);
  if (dnsError) {
    throw new HttpsError("invalid-argument", dnsError, {
      code: "INVALID_EMAIL_DOMAIN",
    });
  }

  // ── 4a. Check for duplicate email in Firebase Auth ─────────────────────────
  const emailInAuth = await checkAuthEmailExists(email);

  if (emailInAuth) {
    throw new HttpsError(
      "already-exists",
      "Sorry, an account with this email already exists.",
      {code: "EMAIL_ALREADY_EXISTS"},
    );
  }

  // ── 4b. Check for duplicate email in Firestore ─────────────────────────────
  const emailInFirestore = await checkEmailExistsInFirestore(email);

  if (emailInFirestore) {
    throw new HttpsError(
      "already-exists",
      "Sorry, an account with this email already exists.",
      {code: "EMAIL_ALREADY_EXISTS"},
    );
  }

  // ── 4c. Check for duplicate member code in Firestore ──────────────────────
  const memberCodeExists = await checkMemberCodeExists(memberCode);

  if (memberCodeExists) {
    throw new HttpsError(
      "already-exists",
      "Sorry, this member code is already registered.",
      {code: "MEMBER_CODE_ALREADY_EXISTS"},
    );
  }

  // ── 5. Generate a secure temporary password (backend only, never sent from client) ──
  const temporaryPassword = generateTemporaryPassword();

  // ── 6 & 7. Create Firebase Auth account, then Firestore profile ────────────
  let uid: string | null = null;
  let firestoreCreated = false;

  try {
    uid = await createAuthUser({
      email,
      password: temporaryPassword,
      displayName: name,
    });

    await createUserProfile({
      user_id: uid,
      member_code: memberCode,
      name,
      email,
      role: role as "Student" | "Staff",
      department,
      phone,
      status: "Active",
      created_at: FieldValue.serverTimestamp() as FirebaseFirestore.Timestamp,
      password_change_required: true,
    });

    firestoreCreated = true;

    // ── 8. Send welcome email ─────────────────────────────────────────────────
    const emailResult = await sendWelcomeEmail({
      to: email,
      name,
      memberCode,
      role,
      department,
      temporaryPassword,
    });

    return {
      success: true,
      message: "User added successfully. Login credentials have been sent for delivery (SMTP submission accepted; mailbox delivery unconfirmed).",
      userId: uid,
      emailStatus: {
        submitted: emailResult.accepted,
        messageId: emailResult.messageId,
        smtpResponse: emailResult.response,
        confirmedDelivery: false,
        note: "Accepted by SMTP server for transmission. Note: SMTP acceptance does not guarantee final inbox delivery.",
      },
      ...(process.env.FUNCTIONS_EMULATOR === "true" ? {temporaryPassword} : {}),
    };
  } catch (error: unknown) {
    // ── Rollback ────────────────────────────────────────────────────────────
    // If email sending failed AFTER Auth + Firestore were created, clean up
    // both so we never leave a user without credentials.
    if (uid !== null && firestoreCreated) {
      // Email sending failed: roll back Firestore profile.
      try {
        await deleteUserProfile(uid);
      } catch (fsDeleteErr) {
        console.error("[createUser] Rollback: failed to delete Firestore profile:", fsDeleteErr);
      }
      // Roll back Auth account.
      try {
        await deleteAuthUser(uid);
      } catch (authDeleteErr) {
        console.error("[createUser] Rollback: failed to delete Auth account:", authDeleteErr);
      }

      // ── Debug: log safe SMTP error details (never logs password) ─────────────
      if (error instanceof Error) {
        const smtpErr = error as Error & {
          code?: string;
          responseCode?: number;
          response?: string;
        };
        console.error("[createUser] SMTP error details:", {
          name: smtpErr.name,
          code: smtpErr.code,
          message: smtpErr.message,
          responseCode: smtpErr.responseCode,
          response: smtpErr.response,
        });
      } else {
        console.error("[createUser] SMTP error (non-Error thrown):", String(error));
      }
      // ─────────────────────────────────────────────────────────────────────────

      console.error("[createUser] Email send failed, account rolled back.");
      throw new HttpsError(
        "internal",
        "User could not be added because the welcome email could not be sent.",
        {code: "EMAIL_SEND_FAILED"},
      );
    }

    // Auth succeeded but Firestore failed: roll back Auth only.
    if (uid !== null && !firestoreCreated) {
      try {
        await deleteAuthUser(uid);
      } catch (authDeleteErr) {
        console.error("[createUser] Rollback: failed to delete Auth account:", authDeleteErr);
      }

      console.error("[createUser] Firestore creation failed, Auth account rolled back:", error);
      throw new HttpsError(
        "internal",
        "Unable to create the user. Please try again.",
        {code: "USER_CREATION_FAILED"},
      );
    }

    // Auth itself failed — nothing to roll back.
    console.error("[createUser] Auth creation failed:", error);
    throw new HttpsError(
      "internal",
      "Unable to create the user. Please try again.",
      {code: "FIREBASE_ERROR"},
    );
  }
});

// ── Member Code → Email Lookup ───────────────────────────────────────────────
// Public callable (no auth required) used by the mobile app to resolve a
// member code into an email address during the login flow.
// Returns only the email — no other profile data is exposed.
export const lookupEmailByMemberCode = onCall(async (request) => {
  const memberCode = ((request.data?.memberCode ?? "") as string).trim().toUpperCase();

  if (!memberCode) {
    throw new HttpsError(
      "invalid-argument",
      "Member code is required.",
      {code: "INVALID_DATA"},
    );
  }

  const snapshot = await adminDb
    .collection("USERS")
    .where("member_code", "==", memberCode)
    .limit(1)
    .get();

  if (snapshot.empty) {
    throw new HttpsError(
      "not-found",
      "No account found with this member code.",
      {code: "NOT_FOUND"},
    );
  }

  const email = snapshot.docs[0].data().email as string;

  return {email};
});

// ── Complaint Submission (Phase 2 AI Detection) ─────────────────────────────
export const submitComplaint = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to report an issue.",
      { code: "UNAUTHORIZED" }
    );
  }

  const uid = request.auth.uid;

  // ── Verify account status is Active ──────────────────────────────────────
  const callerProfile = await getUserProfile(uid);

  if (!callerProfile) {
    throw new HttpsError(
      "permission-denied",
      "User profile not found.",
      {code: "PROFILE_NOT_FOUND"},
    );
  }

  if (callerProfile.status !== "Active") {
    throw new HttpsError(
      "permission-denied",
      "Your account is not active. Please verify your email or contact the administrator.",
      {code: "ACCOUNT_NOT_ACTIVE"},
    );
  }

  try {
    const result = await processNewComplaint(request.data, uid);
    return result;
  } catch (error) {
    console.error("[submitComplaint] Error:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
      "internal",
      "Failed to submit complaint.",
      { code: "INTERNAL_ERROR" }
    );
  }
});

// ── Scheduled Automatic Priority Recalculation (Aging Unresolved Complaints) ──
// Runs every 12 hours to update priority scores for Open and In Progress issues as they age.
// Closed issues are explicitly excluded (their priority does not increase over time).
export const recalculateActiveIssuePriorities = onSchedule("every 12 hours", async (event) => {
  console.log("[recalculateActiveIssuePriorities] Starting scheduled priority recalculation...");

  const activeIssuesSnapshot = await adminDb
    .collection("ISSUES")
    .where("status", "in", ["Open", "In Progress"])
    .get();

  if (activeIssuesSnapshot.empty) {
    console.log("[recalculateActiveIssuePriorities] No active issues to recalculate.");
    return;
  }

  const batch = adminDb.batch();
  let updatedCount = 0;
  const now = new Date();

  for (const doc of activeIssuesSnapshot.docs) {
    const data = doc.data();
    const reporterCount = typeof data.reporter_count === "number" ? data.reporter_count : 1;
    const createdAt = data.created_at?.toDate ? data.created_at.toDate() : now;
    const safetyRisk = Boolean(data.safety_risk);
    const currentPriority = data.priority;

    const calc = calculatePriorityScore({
      reporterCount,
      createdAt,
      safetyRisk,
      now,
    });

    if (calc.priority !== currentPriority) {
      batch.update(doc.ref, {
        priority: calc.priority,
        updated_at: FieldValue.serverTimestamp(),
      });
      updatedCount++;
    }
  }

  if (updatedCount > 0) {
    await batch.commit();
    console.log(`[recalculateActiveIssuePriorities] Successfully updated priorities for ${updatedCount} active issue(s).`);
  } else {
    console.log("[recalculateActiveIssuePriorities] All active issue priorities are already up to date.");
  }
});

// ── 9. Notification Trigger ──────────────────────────────────────────────────
export const sendNotificationOnCreate = onDocumentCreated("NOTIFICATIONS/{notificationId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data associated with the event");
    return;
  }

  const data = snapshot.data();
  const userId = data.user_id;
  const notificationId = event.params.notificationId;

  if (!userId) {
    console.log(`[Notification ${notificationId}] No user_id found in the notification document`);
    return;
  }

  // Find the target user in Firestore
  const userDoc = await adminDb.collection("USERS").doc(userId).get();

  if (!userDoc.exists) {
    console.log(`[Notification ${notificationId}] Target user ${userId} not found in USERS collection`);
    return;
  }

  const userData = userDoc.data() || {};
  const fcmToken = userData.fcm_token;

  if (!fcmToken) {
    console.log(`[Notification ${notificationId}] Target user ${userId} has no FCM token. Skipping notification.`);
    return;
  }

  // Prepare FCM Message
  const message = {
    token: fcmToken,
    notification: {
      title: data.title || "Notification",
      body: data.message || "",
    },
    data: {
      event_id: data.event_id || "",
      type: data.type || "",
    },
  };

  console.log(`[Notification ${notificationId}] Prepared FCM Payload for user ${userId}:`, JSON.stringify(message));

  // Real FCM delivery logic
  try {
    const response = await adminMessaging.send(message);
    console.log(`[Notification ${notificationId}] Successfully sent FCM message to user ${userId}. Message ID: ${response}`);
  } catch (error: any) {
    console.error(`[Notification ${notificationId}] Error sending FCM message to user ${userId}:`, error);
    
    // Check for invalid or unregistered tokens and clean them up
    if (
      error?.code === "messaging/invalid-registration-token" ||
      error?.code === "messaging/registration-token-not-registered" ||
      error?.code === "messaging/invalid-argument"
    ) {
      console.log(`[Notification ${notificationId}] Token is invalid or unregistered. Removing token for user ${userId}.`);
      try {
        await adminDb.collection("USERS").doc(userId).update({
          fcm_token: FieldValue.delete(),
        });
        console.log(`[Notification ${notificationId}] Successfully removed invalid FCM token for user ${userId}.`);
      } catch (cleanupError) {
        console.error(`[Notification ${notificationId}] Failed to remove invalid FCM token for user ${userId}:`, cleanupError);
      }
    }
  }
});
