const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'sunnah-grandeur'
  });
}

const auth = admin.auth();
const db = admin.firestore();

async function setSuperAdminPassword() {
  const email = 'sunnahgrandeur.nyc@gmail.com';
  console.log(`Locating Super Admin account: ${email}...`);

  const user = await auth.getUserByEmail(email);
  console.log(`Found Super Admin UID: ${user.uid}`);

  // Ensure role superAdmin claim is set
  await auth.setCustomUserClaims(user.uid, { role: 'superAdmin', admin: true });
  console.log(`Custom claims set: { role: 'superAdmin', admin: true }`);

  // Set secure administrative access password
  const newPassword = 'SuperAdminPass2026!';
  await auth.updateUser(user.uid, { password: newPassword });
  console.log(`Password successfully set for ${email}: ${newPassword}`);
}

setSuperAdminPassword().catch((err) => {
  console.error('Error updating Super Admin credentials:', err);
  process.exit(1);
});
