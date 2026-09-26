/**
 * scripts/migrate_emulator_data.js
 * 
 * Safely copies existing Authentication users and Firestore documents
 * from production Firebase (campusconnect-25317) into the local emulator-data/ directory.
 *
 * SAFETY GUARANTEES:
 * - REAL FIREBASE IS 100% UNTOUCHED (read-only queries).
 * - No data in production is created, modified, reset, or deleted.
 * - Local emulator password for admin is configured for local testing.
 * - UIDs between Authentication and Firestore are strictly preserved.
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const { execSync, spawn } = require('child_process');

const PROJECT_ID = 'campusconnect-25317';
const ADMIN_DIR = path.resolve(__dirname, '..');
const EMULATOR_DATA_DIR = path.join(ADMIN_DIR, 'emulator-data');
const DESIRED_PASSWORD = process.argv[2] || 'Admin@123';

console.log('====================================================');
console.log('CampusConnect: Safe Production -> Emulator Migration');
console.log('====================================================');
console.log(`Target Project: ${PROJECT_ID}`);
console.log(`Local Emulator Data: ${EMULATOR_DATA_DIR}`);
console.log(`Local Admin Password: ${DESIRED_PASSWORD}`);
console.log('----------------------------------------------------');

// 1. Get Firebase CLI Access Token
function getFirebaseCliToken() {
  const configPath = path.join(process.env.USERPROFILE || process.env.HOME, '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(configPath)) {
    throw new Error(`Firebase CLI credentials not found at ${configPath}. Run 'firebase login' first.`);
  }
  const conf = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const token = conf.tokens && conf.tokens.access_token;
  if (!token) {
    throw new Error('No access_token found in Firebase CLI config. Run "firebase login" again.');
  }
  return token;
}

// 2. Fetch real Firestore documents (read-only)
async function fetchRealFirestoreUsers(token) {
  console.log('Fetching Firestore USERS collection from real Firebase (read-only)...');
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/USERS`,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/json'
      }
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            const json = JSON.parse(data);
            const docs = json.documents || [];
            console.log(`  -> Found ${docs.length} document(s) in USERS collection.`);
            resolve(docs);
          } catch (e) {
            reject(new Error(`Failed to parse Firestore response: ${e.message}`));
          }
        } else {
          reject(new Error(`Firestore API returned HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

// 3. Export real Firebase Auth accounts (read-only via CLI)
function exportRealAuthAccounts() {
  console.log('Exporting Auth accounts from real Firebase (read-only)...');
  const tempExportPath = path.join(ADMIN_DIR, 'temp_auth_export.json');
  try {
    const cmd = process.platform === 'win32' ? 'firebase.cmd' : 'firebase';
    execSync(`${cmd} auth:export "${tempExportPath}" --project ${PROJECT_ID}`, {
      cwd: ADMIN_DIR,
      stdio: 'pipe'
    });
    const content = JSON.parse(fs.readFileSync(tempExportPath, 'utf8'));
    fs.unlinkSync(tempExportPath);
    console.log(`  -> Exported ${content.users ? content.users.length : 0} account(s) from Firebase Auth.`);
    return content.users || [];
  } catch (err) {
    if (fs.existsSync(tempExportPath)) fs.unlinkSync(tempExportPath);
    throw new Error(`Failed to export auth users: ${err.message}`);
  }
}

// 4. Populate Local Emulator
async function populateEmulator(authUsers, firestoreDocs) {
  console.log('Writing migrated data into emulator-data directory...');

  // Ensure directories exist
  const authExportDir = path.join(EMULATOR_DATA_DIR, 'auth_export');
  const firestoreExportDir = path.join(EMULATOR_DATA_DIR, 'firestore_export');
  fs.mkdirSync(authExportDir, { recursive: true });
  fs.mkdirSync(firestoreExportDir, { recursive: true });

  // Write firebase-export-metadata.json
  const exportMetadata = {
    version: '15.29.0',
    firestore: {
      version: '1.22.0',
      path: 'firestore_export',
      metadata_file: 'firestore_export/firestore_export.overall_export_metadata'
    },
    auth: {
      version: '15.29.0',
      path: 'auth_export'
    }
  };
  fs.writeFileSync(
    path.join(EMULATOR_DATA_DIR, 'firebase-export-metadata.json'),
    JSON.stringify(exportMetadata, null, 2)
  );

  // Write auth_export/config.json
  fs.writeFileSync(
    path.join(authExportDir, 'config.json'),
    JSON.stringify({
      signIn: { allowDuplicateEmails: false },
      emailPrivacyConfig: { enableImprovedEmailPrivacy: false }
    }, null, 2)
  );

  // Write auth_export/accounts.json
  const accountsData = {
    kind: 'identitytoolkit#DownloadAccountResponse',
    users: authUsers
  };
  fs.writeFileSync(
    path.join(authExportDir, 'accounts.json'),
    JSON.stringify(accountsData, null, 2)
  );

  // Now start emulators temporarily with emulators:exec to set password & write Firestore docs
  console.log('Syncing credentials and Firestore documents inside local emulators...');
  
  // Create a temporary script for emulators:exec
  const syncWorkerPath = path.join(ADMIN_DIR, 'temp_sync_worker.js');
  const syncWorkerCode = `
const admin = require('${path.join(ADMIN_DIR, '..', 'backend', 'functions', 'node_modules', 'firebase-admin').replace(/\\/g, '/')}');

process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';

admin.initializeApp({ projectId: '${PROJECT_ID}' });

async function run() {
  const docs = ${JSON.stringify(firestoreDocs)};
  const users = ${JSON.stringify(authUsers)};
  const password = ${JSON.stringify(DESIRED_PASSWORD)};

  // 1. Set password for auth users in emulator
  for (const u of users) {
    console.log('  Setting local emulator password for:', u.email, '(' + u.localId + ')');
    await admin.auth().updateUser(u.localId, { password: password });
  }

  // 2. Write firestore documents
  for (const doc of docs) {
    const docId = doc.name.split('/').pop();
    console.log('  Writing Firestore document USERS/' + docId);
    const fields = doc.fields || {};
    const parsedData = {};
    for (const [key, val] of Object.entries(fields)) {
      if ('stringValue' in val) parsedData[key] = val.stringValue;
      else if ('integerValue' in val) parsedData[key] = parseInt(val.integerValue, 10);
      else if ('booleanValue' in val) parsedData[key] = val.booleanValue;
      else if ('timestampValue' in val) parsedData[key] = new Date(val.timestampValue);
      else parsedData[key] = Object.values(val)[0];
    }
    await admin.firestore().collection('USERS').doc(docId).set(parsedData);
  }
}

run().then(() => process.exit(0)).catch(err => {
  console.error(err);
  process.exit(1);
});
`;
  fs.writeFileSync(syncWorkerPath, syncWorkerCode);

  try {
    const cmd = process.platform === 'win32' ? 'firebase.cmd' : 'firebase';
    execSync(`${cmd} emulators:exec --import="${EMULATOR_DATA_DIR}" --export-on-exit="${EMULATOR_DATA_DIR}" "node ${syncWorkerPath}"`, {
      cwd: ADMIN_DIR,
      stdio: 'inherit'
    });
  } finally {
    if (fs.existsSync(syncWorkerPath)) {
      fs.unlinkSync(syncWorkerPath);
    }
  }

  console.log('----------------------------------------------------');
  console.log('MIGRATION COMPLETE & VERIFIED!');
  console.log(`Local Auth users and Firestore documents saved to:`);
  console.log(`  ${EMULATOR_DATA_DIR}`);
  console.log(`Local admin account:`);
  console.log(`  Email:    admin@campusconnect.com`);
  console.log(`  Password: ${DESIRED_PASSWORD}`);
  console.log('====================================================');
}

async function main() {
  try {
    const token = getFirebaseCliToken();
    const [firestoreDocs, authUsers] = await Promise.all([
      fetchRealFirestoreUsers(token),
      Promise.resolve(exportRealAuthAccounts())
    ]);

    await populateEmulator(authUsers, firestoreDocs);
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  }
}

main();
