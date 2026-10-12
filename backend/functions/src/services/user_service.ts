import {adminDb} from "../config/firebase";

interface UserProfile {
  user_id: string;
  member_code: string;
  name: string;
  email: string;
  role: "Student" | "Staff";
  department: string;
  phone: string;
  created_at: FirebaseFirestore.Timestamp;
  status: "Active" | "Inactive";
  password_change_required: boolean;
}

export async function checkMemberCodeExists(
  memberCode: string,
): Promise<boolean> {
  const memberCodeSnapshot = await adminDb
    .collection("USERS")
    .where("member_code", "==", memberCode)
    .limit(1)
    .get();

  return !memberCodeSnapshot.empty;
}

export async function checkEmailExistsInFirestore(
  email: string,
): Promise<boolean> {
  const emailSnapshot = await adminDb
    .collection("USERS")
    .where("email", "==", email)
    .limit(1)
    .get();

  return !emailSnapshot.empty;
}

export async function createUserProfile(
  profile: UserProfile,
): Promise<void> {
  await adminDb
    .collection("USERS")
    .doc(profile.user_id)
    .set(profile);
}

export async function deleteUserProfile(userId: string): Promise<void> {
  await adminDb
    .collection("USERS")
    .doc(userId)
    .delete();
}


/**
 * Retrieves a user's email from the USERS collection by UID.
 * Returns null if the document does not exist.
 */
export async function getUserEmailByUid(uid: string): Promise<string | null> {
  const doc = await adminDb.collection("USERS").doc(uid).get();
  if (!doc.exists) return null;
  return (doc.data()?.email as string) ?? null;
}

/**
 * Retrieves the full user profile from the USERS collection by UID.
 * Returns null if the document does not exist.
 */
export async function getUserProfile(uid: string): Promise<{
  email: string;
  name: string;
  status: string;
  member_code: string;
  role: string;
  department: string;
} | null> {
  const doc = await adminDb.collection("USERS").doc(uid).get();
  if (!doc.exists) return null;
  const data = doc.data()!;
  return {
    email: (data.email as string) ?? "",
    name: (data.name as string) ?? "",
    status: (data.status as string) ?? "",
    member_code: (data.member_code as string) ?? "",
    role: (data.role as string) ?? "",
    department: (data.department as string) ?? "",
  };
}
