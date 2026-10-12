/**
 * test_account_creation.mjs
 *
 * Comprehensive integration test for the restored simple account creation flow:
 * 1. Verifies unauthenticated callers are rejected.
 * 2. Verifies non-admin callers are rejected.
 * 3. Verifies invalid data is rejected.
 * 4. Successfully creates a student account via `createUser` callable function.
 * 5. Verifies Firestore profile has status: "Active" and password_change_required: true.
 * 6. Verifies user can immediately sign in using email and the generated temporary password.
 * 7. Verifies invalid password is rejected.
 * 8. Verifies duplicate email is rejected.
 * 9. Verifies duplicate member code is rejected.
 * 10. Verifies lookupEmailByMemberCode resolves member code to email.
 */

import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

const AUTH_HOST = 'http://127.0.0.1:9099';
const FUNCTIONS_HOST = 'http://127.0.0.1:5001/campusconnect-25317/us-central1';
const PROJECT_ID = 'campusconnect-25317';

const ADMIN_EMAIL = 'admin@campusconnect.com';
const ADMIN_PASSWORD = 'Admin@123';

const STUDENT_EMAIL = 'regular_student@campusconnect.com';
const STUDENT_PASSWORD = 'Student@123';
let studentUid = null;

let adminIdToken = null;
let studentIdToken = null;
let testEnv = null;

describe('Account Creation Flow (Restored Simple Flow)', () => {

  before(async () => {
    // 1. Initialize Firestore test environment to seed data bypassing rules
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        host: '127.0.0.1',
        port: 8080,
      },
    });

    // 2. Create or ensure Admin in Auth
    let adminUid = null;
    const adminSignUpRes = await fetch(`${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
        returnSecureToken: true,
      }),
    });
    const adminSignUpData = await adminSignUpRes.json();
    if (adminSignUpData.idToken) {
      adminIdToken = adminSignUpData.idToken;
      adminUid = adminSignUpData.localId;
    } else {
      const signInRes = await fetch(`${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: ADMIN_EMAIL,
          password: ADMIN_PASSWORD,
          returnSecureToken: true,
        }),
      });
      const signInData = await signInRes.json();
      assert.ok(signInData.idToken, 'Admin sign-in must succeed');
      adminIdToken = signInData.idToken;
      adminUid = signInData.localId;
    }

    // 3. Create regular student user (non-admin) in Auth
    const stuSignUpRes = await fetch(`${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: STUDENT_EMAIL,
        password: STUDENT_PASSWORD,
        returnSecureToken: true,
      }),
    });
    const stuData = await stuSignUpRes.json();
    if (stuData.idToken) {
      studentUid = stuData.localId;
      studentIdToken = stuData.idToken;
    } else {
      const stuSignInRes = await fetch(`${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: STUDENT_EMAIL,
          password: STUDENT_PASSWORD,
          returnSecureToken: true,
        }),
      });
      const stuSignInData = await stuSignInRes.json();
      assert.ok(stuSignInData.idToken, 'Student sign-in must succeed');
      studentUid = stuSignInData.localId;
      studentIdToken = stuSignInData.idToken;
    }

    // 4. Seed Firestore documents with rules bypassed
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, 'USERS', adminUid), {
        role: 'Admin',
        status: 'Active',
        email: ADMIN_EMAIL,
        name: 'Super Admin',
        member_code: 'ADM001',
        department: 'Administration',
        phone: '9999999999',
        password_change_required: false,
      });

      await setDoc(doc(db, 'USERS', studentUid), {
        role: 'Student',
        status: 'Active',
        email: STUDENT_EMAIL,
        name: 'Normal Student',
        member_code: 'STU001',
        department: 'MCA',
        phone: '9876543210',
        password_change_required: false,
      });
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  it('1. Rejects unauthenticated caller', async () => {
    const res = await fetch(`${FUNCTIONS_HOST}/createUser`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        data: {
          memberCode: 'TEST001',
          name: 'Test Student',
          email: 'test@student.com',
          role: 'Student',
          department: 'MCA',
          phone: '9876543210',
        },
      }),
    });

    const data = await res.json();
    assert.equal(res.status, 401, 'Unauthenticated request must return 401');
    assert.equal(data.error?.status, 'UNAUTHENTICATED');
  });

  it('2. Rejects non-admin caller', async () => {
    const res = await fetch(`${FUNCTIONS_HOST}/createUser`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${studentIdToken}`,
      },
      body: JSON.stringify({
        data: {
          memberCode: 'TEST002',
          name: 'Test Student 2',
          email: 'test2@student.com',
          role: 'Student',
          department: 'MCA',
          phone: '9876543210',
        },
      }),
    });

    const data = await res.json();
    assert.equal(res.status, 403, 'Non-admin request must return 403');
    assert.equal(data.error?.status, 'PERMISSION_DENIED');
  });

  it('3a. Rejects malformed email syntax before account creation', async () => {
    const malformedEmails = [
      'not-an-email',
      '@missinglocal.org',
      'missingdomain@',
      'user@bad..domain.com',
      'user@.leadingdot.com',
      'user@nodotdomain',
    ];

    for (const badEmail of malformedEmails) {
      const res = await fetch(`${FUNCTIONS_HOST}/createUser`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminIdToken}`,
        },
        body: JSON.stringify({
          data: {
            memberCode: `BAD${Date.now().toString().slice(-4)}`,
            name: 'Bad Email Student',
            email: badEmail,
            role: 'Student',
            department: 'MCA',
            phone: '9876543210',
          },
        }),
      });

      const data = await res.json();
      assert.equal(
        res.status,
        400,
        `Malformed email '${badEmail}' must return 400, got: ${res.status}`,
      );
      assert.equal(data.error?.status, 'INVALID_ARGUMENT');
    }
  });

  it('3b. Rejects nonexistent email domain with no mail records before account creation', async () => {
    const res = await fetch(`${FUNCTIONS_HOST}/createUser`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminIdToken}`,
      },
      body: JSON.stringify({
        data: {
          memberCode: `NXD${Date.now().toString().slice(-4)}`,
          name: 'Nonexistent Domain Student',
          email: 'validuser@this-nonexistent-domain-xyz98712345.org',
          role: 'Student',
          department: 'MCA',
          phone: '9876543210',
        },
      }),
    });

    const data = await res.json();
    assert.equal(
      res.status,
      400,
      `Nonexistent domain must return 400, got ${res.status}`,
    );
    assert.equal(data.error?.status, 'INVALID_ARGUMENT');
    assert.match(
      data.error?.message,
      /does not exist|does not have valid mail-routing/i,
    );
  });

  const testRunId = Date.now().toString().slice(-5);
  let createdUserId = null;
  let receivedTemporaryPassword = null;
  const newMemberCode = `STU${testRunId}`;
  const newEmail = `student${testRunId}@campusconnect.test`;

  it('4. Successfully creates student account and distinguishes SMTP submission from confirmed delivery', async () => {
    const res = await fetch(`${FUNCTIONS_HOST}/createUser`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminIdToken}`,
      },
      body: JSON.stringify({
        data: {
          memberCode: newMemberCode,
          name: 'New Student Test',
          email: newEmail,
          role: 'Student',
          department: 'MCA',
          phone: '9876543210',
        },
      }),
    });

    const data = await res.json();
    assert.equal(res.status, 200, `Expected 200 OK, got: ${JSON.stringify(data)}`);
    assert.equal(data.result?.success, true);
    assert.match(data.result?.message, /credentials have been sent/i);
    assert.ok(data.result?.userId, 'Must return created user ID');
    assert.ok(data.result?.temporaryPassword, 'Must return temporary password in emulator');

    // Requirement 2: Distinguish SMTP acceptance from confirmed mailbox delivery
    assert.ok(data.result?.emailStatus, 'Must return emailStatus in response');
    assert.equal(data.result.emailStatus.submitted, true, 'SMTP submitted must be true');
    assert.equal(
      data.result.emailStatus.confirmedDelivery,
      false,
      'confirmedDelivery must be false because SMTP acceptance is not proof of inbox delivery',
    );

    createdUserId = data.result.userId;
    receivedTemporaryPassword = data.result.temporaryPassword;
  });

  it('5. Firestore profile has status: "Active" and password_change_required: true', async () => {
    assert.ok(createdUserId, 'Must have created user ID from previous test');

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const userSnap = await getDoc(doc(db, 'USERS', createdUserId));
      assert.ok(userSnap.exists(), 'Firestore document must exist');
      const data = userSnap.data();
      assert.equal(data.status, 'Active', 'Status must be Active (permits login)');
      assert.equal(data.password_change_required, true, 'password_change_required must be true');
      assert.equal(data.member_code, newMemberCode);
      assert.equal(data.email, newEmail);
      assert.equal(data.role, 'Student');
      assert.equal(data.department, 'MCA');
    });
  });

  it('6. User can immediately sign in using email and the generated temporary password', async () => {
    assert.ok(receivedTemporaryPassword, 'Must have received temporary password');

    // Wrong password should fail
    const wrongPassRes = await fetch(`${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: newEmail,
        password: 'WrongPassword!123',
        returnSecureToken: true,
      }),
    });
    const wrongPassData = await wrongPassRes.json();
    assert.equal(wrongPassRes.status, 400, 'Wrong password must be rejected');
    assert.match(wrongPassData.error?.message, /INVALID_LOGIN_CREDENTIALS|INVALID_PASSWORD/);

    // Correct temporary password must succeed
    const correctPassRes = await fetch(`${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: newEmail,
        password: receivedTemporaryPassword,
        returnSecureToken: true,
      }),
    });
    const correctPassData = await correctPassRes.json();
    assert.equal(correctPassRes.status, 200, 'Correct temporary password sign-in must succeed');
    assert.ok(correctPassData.idToken, 'Must receive idToken on successful login');
    assert.equal(correctPassData.localId, createdUserId, 'Signed-in user UID must match created UID');
  });

  it('7. Rejects duplicate email', async () => {
    const res = await fetch(`${FUNCTIONS_HOST}/createUser`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminIdToken}`,
      },
      body: JSON.stringify({
        data: {
          memberCode: `DIFF${Date.now().toString().slice(-4)}`,
          name: 'Duplicate Email Person',
          email: newEmail,
          role: 'Student',
          department: 'MCA',
          phone: '9876543210',
        },
      }),
    });

    const data = await res.json();
    assert.equal(res.status, 409, 'Duplicate email must return 409');
    assert.equal(data.error?.status, 'ALREADY_EXISTS');
  });

  it('8. Rejects duplicate member code', async () => {
    const res = await fetch(`${FUNCTIONS_HOST}/createUser`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminIdToken}`,
      },
      body: JSON.stringify({
        data: {
          memberCode: newMemberCode,
          name: 'Duplicate Code Person',
          email: `different${Date.now().toString().slice(-4)}@campusconnect.test`,
          role: 'Student',
          department: 'MCA',
          phone: '9876543210',
        },
      }),
    });

    const data = await res.json();
    assert.equal(res.status, 409, 'Duplicate member code must return 409');
    assert.equal(data.error?.status, 'ALREADY_EXISTS');
  });

  it('9. lookupEmailByMemberCode resolves member code to email', async () => {
    const res = await fetch(`${FUNCTIONS_HOST}/lookupEmailByMemberCode`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        data: { memberCode: newMemberCode },
      }),
    });

    const data = await res.json();
    assert.equal(res.status, 200);
    assert.equal(data.result?.email, newEmail);
  });

  it('10. Email content matches required format and includes no verification links', async () => {
    // Import sendWelcomeEmail and test formatted email content directly
    const { sendWelcomeEmail } = await import('../functions/lib/services/email_service.js');
    process.env.SMTP_HOST = 'mock';

    const testUserData = {
      to: 'student@example.test',
      name: 'John Doe',
      memberCode: 'STU001',
      role: 'Student',
      department: 'MCA',
      temporaryPassword: 'CC#tempPassword!9',
    };

    const result = await sendWelcomeEmail(testUserData);
    assert.equal(result.accepted, true);

    // Verify email content template by reading the source or calling with mock
    const fs = await import('fs/promises');
    const emailServiceSource = await fs.readFile(
      new URL('../functions/src/services/email_service.ts', import.meta.url),
      'utf8',
    );

    // Verify required fields
    assert.ok(emailServiceSource.includes('${data.name}'), 'Must include full name');
    assert.ok(emailServiceSource.includes('${data.memberCode}'), 'Must include member code');
    assert.ok(emailServiceSource.includes('${data.role}'), 'Must include role');
    assert.ok(emailServiceSource.includes('${data.department}'), 'Must include department');
    assert.ok(emailServiceSource.includes('${data.to}'), 'Must include login email');
    assert.ok(emailServiceSource.includes('${data.temporaryPassword}'), 'Must include temporary password');

    // Verify exact required ending
    const requiredEnding =
      'Use your login email and temporary password to sign in to CampusConnect. For security, please change your password after your first login.';
    assert.ok(
      emailServiceSource.includes(requiredEnding),
      'Must end with required instruction text',
    );

    // Verify prohibited links
    assert.ok(!emailServiceSource.includes('verify'), 'Must not contain email verification');
    assert.ok(!emailServiceSource.includes('reset'), 'Must not contain password reset');
    assert.ok(!emailServiceSource.includes('http://'), 'Must not contain http links');
    assert.ok(!emailServiceSource.includes('https://'), 'Must not contain https links');
  });

  it('11. Rollback behavior: sendWelcomeEmail throws on simulated SMTP failure', async () => {
    const { sendWelcomeEmail } = await import('../functions/lib/services/email_service.js');
    process.env.SMTP_HOST = 'fail';

    await assert.rejects(
      async () => {
        await sendWelcomeEmail({
          to: 'student@example.test',
          name: 'Rollback Test',
          memberCode: 'STU999',
          role: 'Student',
          department: 'MCA',
          temporaryPassword: 'CC#tempPassword!9',
        });
      },
      /Simulated SMTP failure for rollback testing/,
    );
  });
});
