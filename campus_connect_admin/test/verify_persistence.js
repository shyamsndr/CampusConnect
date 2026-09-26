/**
 * test/verify_persistence.js
 * 
 * Verifies that data written to the emulators persists across emulator restarts
 * when using --import=./emulator-data --export-on-exit=./emulator-data.
 */

const http = require('http');

const TEST_DOC_ID = 'test_persistence_check';

function writeDoc() {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      fields: {
        testField: { stringValue: 'persisted_successfully' }
      }
    });

    const req = http.request({
      hostname: '127.0.0.1',
      port: 8080,
      path: `/v1/projects/campusconnect-25317/databases/(default)/documents/TEST_COLLECTION/${TEST_DOC_ID}`,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, (res) => {
      if (res.statusCode === 200) {
        console.log('✓ Successfully wrote test document to Firestore emulator.');
        resolve();
      } else {
        reject(new Error(`Failed to write doc: ${res.statusCode}`));
      }
    });
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function verifyDoc() {
  return new Promise((resolve, reject) => {
    const req = http.request({
      hostname: '127.0.0.1',
      port: 8080,
      path: `/v1/projects/campusconnect-25317/databases/(default)/documents/TEST_COLLECTION/${TEST_DOC_ID}`,
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          console.log('✓ Successfully retrieved persisted document after emulator restart!');
          console.log('  Data:', data.trim());
          resolve();
        } else {
          reject(new Error(`Persisted doc not found: ${res.statusCode}`));
        }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

function deleteDoc() {
  return new Promise((resolve, reject) => {
    const req = http.request({
      hostname: '127.0.0.1',
      port: 8080,
      path: `/v1/projects/campusconnect-25317/databases/(default)/documents/TEST_COLLECTION/${TEST_DOC_ID}`,
      method: 'DELETE'
    }, (res) => {
      if (res.statusCode === 200) {
        console.log('✓ Cleaned up test document from emulator.');
        resolve();
      } else {
        reject(new Error(`Failed to delete doc: ${res.statusCode}`));
      }
    });
    req.on('error', reject);
    req.end();
  });
}

const action = process.argv[2];
if (action === 'write') {
  writeDoc().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
} else if (action === 'verify_and_cleanup') {
  verifyDoc()
    .then(() => deleteDoc())
    .then(() => process.exit(0))
    .catch(e => { console.error(e); process.exit(1); });
} else {
  console.log('Usage: node verify_persistence.js [write|verify_and_cleanup]');
  process.exit(1);
}
