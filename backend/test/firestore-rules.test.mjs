/**
 * Firestore Security Rules — Automated Tests
 *
 * Run with emulators already started:
 *   cd backend && npm run test:rules
 *
 * Or start emulators automatically:
 *   cd backend && npm run test:rules:emulators
 *
 * Requires: npm install (in backend/) to install @firebase/rules-unit-testing
 * Requires: Firestore emulator on port 8080
 */

import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc,
  collection, getDocs,
} from 'firebase/firestore';
import { readFileSync } from 'fs';
import { describe, it, before, after } from 'node:test';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

let testEnv;
const ADMIN_UID = 'admin-uid';
const USER1_UID = 'user1-uid';
const USER2_UID = 'user2-uid';

// ── Setup & Teardown ─────────────────────────────────────────────────────────

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-campusconnect',
    firestore: {
      rules: readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });

  // Seed test data with rules bypassed
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    // Admin user
    await setDoc(doc(db, 'USERS', ADMIN_UID), {
      role: 'Admin', status: 'Active', email: 'admin@campus.edu',
      name: 'Admin User', member_code: 'ADM001', department: 'MCA',
      phone: '1234567890', created_at: new Date(), fcm_token: 'token-admin',
    });

    // Regular student
    await setDoc(doc(db, 'USERS', USER1_UID), {
      role: 'Student', status: 'Active', email: 'user1@campus.edu',
      name: 'Student One', member_code: 'STU001', department: 'MCA',
      phone: '2345678901', created_at: new Date(), fcm_token: 'token-1',
    });

    // Regular staff
    await setDoc(doc(db, 'USERS', USER2_UID), {
      role: 'Staff', status: 'Active', email: 'user2@campus.edu',
      name: 'Staff Two', member_code: 'STF001', department: 'MBA',
      phone: '3456789012', created_at: new Date(), fcm_token: 'token-2',
    });

    // Notification owned by user1
    await setDoc(doc(db, 'NOTIFICATIONS', 'notif1'), {
      user_id: USER1_UID, type: 'event_created', title: 'New Event',
      message: 'Test event added', event_id: 'event1',
      created_at: new Date(), is_read: false,
    });

    // Notification owned by user2
    await setDoc(doc(db, 'NOTIFICATIONS', 'notif2'), {
      user_id: USER2_UID, type: 'event_created', title: 'New Event',
      message: 'Test event added', event_id: 'event1',
      created_at: new Date(), is_read: false,
    });

    // Event
    await setDoc(doc(db, 'EVENTS', 'event1'), {
      event_id: 'event1', title: 'Campus Hackathon', description: 'A coding event',
      event_date: new Date(), event_time: '10:00 AM', venue: 'Lab 1',
      poster_url: '', created_at: new Date(), updated_at: new Date(),
      created_by: ADMIN_UID, status: 'published',
    });

    // Issue
    await setDoc(doc(db, 'ISSUES', 'issue1'), {
      issue_id: 'issue1', title: 'Broken AC', description: 'AC not working',
      location: 'Room 101', status: 'Open', priority: 'Medium',
      primary_reporter_id: USER1_UID, created_at: new Date(), updated_at: new Date(),
    });

    // Issue report
    await setDoc(doc(db, 'ISSUE_REPORTS', 'report1'), {
      report_id: 'report1', issue_id: 'issue1', user_id: USER1_UID,
      title: 'Broken AC', description: 'AC not working', location: 'Room 101',
      created_at: new Date(),
    });

    // Issue status history
    await setDoc(doc(db, 'ISSUE_STATUS_HISTORY', 'history1'), {
      history_id: 'history1', issue_id: 'issue1', old_status: null,
      new_status: 'Open', changed_by: USER1_UID, changed_at: new Date(),
    });

    // Email verification record
    await setDoc(doc(db, 'EMAIL_VERIFICATIONS', USER1_UID), {
      uid: USER1_UID, email: 'user1@campus.edu',
      token_hash: 'fakehash', expires_at: new Date(),
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

// ── USERS ────────────────────────────────────────────────────────────────────

describe('USERS collection', () => {
  it('allows owner to read own document', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'USERS', USER1_UID)));
  });

  it('denies non-owner from reading another user document', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(getDoc(doc(db, 'USERS', USER2_UID)));
  });

  it('allows admin to read any user document', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'USERS', USER1_UID)));
  });

  it('allows admin to list all users', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(getDocs(collection(db, 'USERS')));
  });

  it('denies non-admin from listing all users', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(getDocs(collection(db, 'USERS')));
  });

  it('allows owner to update fcm_token only', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertSucceeds(updateDoc(doc(db, 'USERS', USER1_UID), { fcm_token: 'new-token' }));
  });

  it('denies owner from updating role', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(updateDoc(doc(db, 'USERS', USER1_UID), { role: 'Admin' }));
  });

  it('denies owner from updating status', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(updateDoc(doc(db, 'USERS', USER1_UID), { status: 'Inactive' }));
  });

  it('denies owner from updating multiple fields including fcm_token', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(updateDoc(doc(db, 'USERS', USER1_UID), { fcm_token: 'x', name: 'Hacked' }));
  });

  it('denies any client from creating a USERS document', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(setDoc(doc(db, 'USERS', 'new-uid'), { role: 'Student' }));
  });

  it('denies any client from deleting a USERS document', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(deleteDoc(doc(db, 'USERS', USER2_UID)));
  });

  it('denies unauthenticated access', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'USERS', USER1_UID)));
  });
});

// ── EVENTS ───────────────────────────────────────────────────────────────────

describe('EVENTS collection', () => {
  it('allows authenticated user to read', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'EVENTS', 'event1')));
  });

  it('allows admin to create events', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(setDoc(doc(db, 'EVENTS', 'event-new'), {
      title: 'New Event', status: 'published',
    }));
  });

  it('allows admin to update events', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(updateDoc(doc(db, 'EVENTS', 'event1'), { status: 'cancelled' }));
  });

  it('allows admin to delete events', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'EVENTS', 'event-del'), { title: 'temp' });
    });
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(deleteDoc(doc(db, 'EVENTS', 'event-del')));
  });

  it('denies non-admin from creating events', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(setDoc(doc(db, 'EVENTS', 'event-hack'), { title: 'Hack' }));
  });

  it('denies non-admin from updating events', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(updateDoc(doc(db, 'EVENTS', 'event1'), { title: 'Hacked' }));
  });

  it('denies non-admin from deleting events', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(deleteDoc(doc(db, 'EVENTS', 'event1')));
  });

  it('denies unauthenticated access', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'EVENTS', 'event1')));
  });
});

// ── NOTIFICATIONS ────────────────────────────────────────────────────────────

describe('NOTIFICATIONS collection', () => {
  it('allows owner to read own notification', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'NOTIFICATIONS', 'notif1')));
  });

  it('denies non-owner from reading another notification', async () => {
    const db = testEnv.authenticatedContext(USER2_UID).firestore();
    await assertFails(getDoc(doc(db, 'NOTIFICATIONS', 'notif1')));
  });

  it('allows admin to create notifications', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(setDoc(doc(db, 'NOTIFICATIONS', 'notif-new'), {
      user_id: USER1_UID, title: 'Test', message: 'body',
      type: 'event_created', event_id: 'e1', created_at: new Date(), is_read: false,
    }));
  });

  it('denies non-admin from creating notifications', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(setDoc(doc(db, 'NOTIFICATIONS', 'notif-hack'), {
      user_id: USER1_UID, title: 'Hack', message: 'body',
      type: 'event_created', event_id: 'e1', created_at: new Date(), is_read: false,
    }));
  });

  it('allows owner to update is_read only', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertSucceeds(updateDoc(doc(db, 'NOTIFICATIONS', 'notif1'), { is_read: true }));
  });

  it('denies owner from updating other fields', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(updateDoc(doc(db, 'NOTIFICATIONS', 'notif1'), { title: 'Hacked' }));
  });

  it('denies owner from updating is_read and another field', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(updateDoc(doc(db, 'NOTIFICATIONS', 'notif1'), { is_read: true, title: 'X' }));
  });

  it('allows owner to delete own notification', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'NOTIFICATIONS', 'notif-del'), {
        user_id: USER1_UID, title: 'Del', message: 'body', is_read: false,
      });
    });
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertSucceeds(deleteDoc(doc(db, 'NOTIFICATIONS', 'notif-del')));
  });

  it('denies non-owner from deleting notification', async () => {
    const db = testEnv.authenticatedContext(USER2_UID).firestore();
    await assertFails(deleteDoc(doc(db, 'NOTIFICATIONS', 'notif1')));
  });

  it('denies unauthenticated access', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'NOTIFICATIONS', 'notif1')));
  });
});

// ── ISSUES ───────────────────────────────────────────────────────────────────

describe('ISSUES collection', () => {
  it('allows authenticated user to read', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'ISSUES', 'issue1')));
  });

  it('allows admin to update issues', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(updateDoc(doc(db, 'ISSUES', 'issue1'), { status: 'In Progress' }));
  });

  it('denies non-admin from updating issues', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(updateDoc(doc(db, 'ISSUES', 'issue1'), { status: 'Closed' }));
  });

  it('denies non-admin from creating issues', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(setDoc(doc(db, 'ISSUES', 'issue-hack'), { title: 'Hack' }));
  });

  it('denies unauthenticated access', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'ISSUES', 'issue1')));
  });
});

// ── ISSUE_REPORTS ────────────────────────────────────────────────────────────

describe('ISSUE_REPORTS collection', () => {
  it('allows authenticated user to read', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'ISSUE_REPORTS', 'report1')));
  });

  it('denies any client from creating (even admin)', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(setDoc(doc(db, 'ISSUE_REPORTS', 'report-hack'), { title: 'Hack' }));
  });

  it('denies any client from updating', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(updateDoc(doc(db, 'ISSUE_REPORTS', 'report1'), { title: 'Changed' }));
  });

  it('denies any client from deleting', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(deleteDoc(doc(db, 'ISSUE_REPORTS', 'report1')));
  });

  it('denies unauthenticated access', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'ISSUE_REPORTS', 'report1')));
  });
});

// ── ISSUE_STATUS_HISTORY ─────────────────────────────────────────────────────

describe('ISSUE_STATUS_HISTORY collection', () => {
  it('allows authenticated user to read', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertSucceeds(getDoc(doc(db, 'ISSUE_STATUS_HISTORY', 'history1')));
  });

  it('allows admin to create history entries', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(setDoc(doc(db, 'ISSUE_STATUS_HISTORY', 'history-new'), {
      history_id: 'history-new', issue_id: 'issue1', old_status: 'Open',
      new_status: 'In Progress', changed_by: ADMIN_UID, changed_at: new Date(),
    }));
  });

  it('denies non-admin from creating history', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(setDoc(doc(db, 'ISSUE_STATUS_HISTORY', 'history-hack'), {
      issue_id: 'issue1', new_status: 'Closed',
    }));
  });

  it('denies non-admin from updating history', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(updateDoc(doc(db, 'ISSUE_STATUS_HISTORY', 'history1'), {
      new_status: 'Hacked',
    }));
  });

  it('denies unauthenticated access', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'ISSUE_STATUS_HISTORY', 'history1')));
  });
});

// ── EMAIL_VERIFICATIONS ──────────────────────────────────────────────────────

describe('EMAIL_VERIFICATIONS collection', () => {
  it('denies authenticated user from reading', async () => {
    const db = testEnv.authenticatedContext(USER1_UID).firestore();
    await assertFails(getDoc(doc(db, 'EMAIL_VERIFICATIONS', USER1_UID)));
  });

  it('denies admin from reading', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(getDoc(doc(db, 'EMAIL_VERIFICATIONS', USER1_UID)));
  });

  it('denies any client from writing', async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(setDoc(doc(db, 'EMAIL_VERIFICATIONS', 'hack'), { token_hash: 'x' }));
  });

  it('denies unauthenticated access', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'EMAIL_VERIFICATIONS', USER1_UID)));
  });
});
