import { User } from "firebase/auth";

// Emails treated as admin even without a custom claim yet (e.g. freshly
// invited staff/dev accounts). Keep this list short — the real,
// server-enforced authorization is the `role` custom claim checked below
// and in backend/firestore.rules; this list only widens who can pass the
// client-side gate before a claim has been set on their account.
export const ADMIN_EMAIL_ALLOWLIST = [
  "sunnahgrandeur.nyc@gmail.com",
  "admin@sunnahgrandeur.com",
  "talharrc@gmail.com",
  "rihadhamid20@gmail.com",
  "mail.galaxatech@gmail.com",
];

export async function isAuthorizedAdmin(user: User): Promise<boolean> {
  const tokenResult = await user.getIdTokenResult(true);
  const email = user.email?.toLowerCase() ?? "";
  return (
    tokenResult.claims.role === "admin" ||
    tokenResult.claims.role === "superAdmin" ||
    ADMIN_EMAIL_ALLOWLIST.includes(email)
  );
}
