/**
 * test/verify_emulator_environment.js
 * 
 * Verifies that the local Firebase Emulator Suite:
 * 1. Loads Authentication user: admin@campusconnect.com (UID: L5JTNzbrWyfu6RIWomsF9QEWyh13)
 * 2. Authenticates successfully with the configured local password (Admin@123)
 * 3. Returns the matching Firestore document USERS/L5JTNzbrWyfu6RIWomsF9QEWyh13 with role: "Admin"
 * 4. Confirms that UID in Auth and Firestore match exactly
 */

const http = require('http');

const EXPECTED_EMAIL = 'admin@campusconnect.com';
const EXPECTED_UID = 'L5JTNzbrWyfu6RIWomsF9QEWyh13';
const TEST_PASSWORD = process.argv[2] || 'Admin@123';

async function verifyAuth() {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      email: EXPECTED_EMAIL,
      password: TEST_PASSWORD,
      returnSecureToken: true
    });

    const req = http.request({
      hostname: '127.0.0.1',
      port: 9099,
      path: '/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const parsed = JSON.parse(data);
            if (parsed.localId === EXPECTED_UID) {
              console.log('✓ [AUTH] Successfully authenticated admin user:');
              console.log(`         Email: ${parsed.email}`);
              console.log(`         UID:   ${parsed.localId}`);
              resolve(parsed);
            } else {
              reject(new Error(`UID mismatch! Expected ${EXPECTED_UID}, got ${parsed.localId}`));
            }
          } catch (e) {
            reject(new Error(`Failed to parse Auth response: ${e.message}`));
          }
        } else {
          reject(new Error(`Auth sign-in failed with status ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

async function verifyFirestore(authUid) {
  return new Promise((resolve, reject) => {
    const req = http.request({
      hostname: '127.0.0.1',
      port: 8080,
      path: `/v1/projects/campusconnect-25317/databases/(default)/documents/USERS/${authUid}`,
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const parsed = JSON.parse(data);
            const fields = parsed.fields || {};
            const role = fields.role && fields.role.stringValue;
            const name = fields.name && fields.name.stringValue;
            const email = fields.email && fields.email.stringValue;

            console.log('✓ [FIRESTORE] Successfully retrieved USERS profile doc:');
            console.log(`              Doc ID: ${authUid}`);
            console.log(`              Name:   ${name}`);
            console.log(`              Email:  ${email}`);
            console.log(`              Role:   ${role}`);

            if (role !== 'Admin') {
              reject(new Error(`Expected role 'Admin', but found '${role}'`));
            } else {
              resolve(parsed);
            }
          } catch (e) {
            reject(new Error(`Failed to parse Firestore response: ${e.message}`));
          }
        } else {
          reject(new Error(`Firestore query failed with status ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

async function run() {
  console.log('====================================================');
  console.log('Verifying Local Firebase Emulator Suite Data');
  console.log('====================================================');
  try {
    const authResult = await verifyAuth();
    await verifyFirestore(authResult.localId);
    console.log('----------------------------------------------------');
    console.log('ALL VERIFICATIONS PASSED!');
    console.log('Auth Emulator & Firestore Emulator are perfectly in sync.');
    console.log('====================================================');
    process.exit(0);
  } catch (err) {
    console.error('✗ Verification failed:', err.message);
    process.exit(1);
  }
}

run();
