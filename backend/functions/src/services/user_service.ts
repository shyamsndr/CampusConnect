import { adminDb } from "../config/firebase";

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