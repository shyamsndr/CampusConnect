import { adminAuth } from "../config/firebase";

interface CreateAuthUserData {
  email: string;
  password: string;
  displayName: string;
}

export async function createAuthUser(
  data: CreateAuthUserData,
): Promise<string> {
  const userRecord = await adminAuth.createUser({
    email: data.email,
    password: data.password,
    displayName: data.displayName,
  });

  return userRecord.uid;
}

export async function deleteAuthUser(uid: string): Promise<void> {
  await adminAuth.deleteUser(uid);
}

export async function checkAuthEmailExists(email: string): Promise<boolean> {
  try {
    const user = await adminAuth.getUserByEmail(email);
    return !!user;
  } catch (error: any) {
    if (error.code === "auth/user-not-found") {
      return false;
    }
    throw error;
  }
}