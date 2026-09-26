import { randomBytes } from "crypto";

export function generateTemporaryPassword(): string {
  const randomPart = randomBytes(9).toString("base64url");
  return `CC#${randomPart}!9`;
}