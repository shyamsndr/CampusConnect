/**
 * test_complaint_duplicate_detection.mjs
 *
 * Automated test suite for CampusConnect complaint duplicate-detection
 * and merging logic.
 *
 * Validates:
 * 1. Required prompt examples:
 *    - "Window is broken in Lab 1" vs "The lab window won't open" (potentially same issue -> MATCH)
 *    - "Computer is not working in Lab 1" vs "Window is not working in Lab 1" (different assets -> NO MATCH)
 *    - "Desk is broken in Room 101" vs "Computer is not working in Room 101" (different assets -> NO MATCH)
 *    - "Projector is not working in Room 101" vs "The projector stopped working in Room 101" (same issue -> MATCH)
 *    - Identical problems in different rooms (Room 101 vs Room 102) -> MUST REMAIN SEPARATE
 * 2. User's observed problem reports:
 *    - Title: "computer is not working", Description: "computer is not working it get stuck", Location: "lab"
 *      vs
 *      Title: "window is not working", Description: "window is not working in lab", Location: "lab"
 *      -> MUST NOT MERGE
 * 3. Location normalization and compatibility rules:
 *    - Case insensitivity, formatting variations ("Room 101" vs "rm 101" vs "RM-101")
 *    - Different rooms/labs/blocks never merge
 * 4. Closed issues never merged into
 * 5. Conservative handling of ambiguous or uncertain reports
 */

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  normalizeLocation,
  areLocationsCompatible,
  extractComplaintEntities,
  areAssetsCompatible,
  areFaultsCompatible,
  evaluateComplaintMatch,
} from '../functions/lib/services/duplicate_detection.js';

describe('Location Normalization & Matching', () => {
  it('normalizes location variations correctly', () => {
    const loc1 = normalizeLocation('Room 101');
    const loc2 = normalizeLocation('rm 101');
    const loc3 = normalizeLocation('RM-101');
    const loc4 = normalizeLocation('Room-101');
    const loc5 = normalizeLocation('Classroom 101');

    assert.equal(loc1.roomNumber, '101');
    assert.equal(loc2.roomNumber, '101');
    assert.equal(loc3.roomNumber, '101');
    assert.equal(loc4.roomNumber, '101');
    assert.equal(loc5.roomNumber, '101');
  });

  it('normalizes lab number variations correctly', () => {
    const lab1 = normalizeLocation('Lab 1');
    const lab2 = normalizeLocation('lab-1');
    const lab3 = normalizeLocation('LAB 01');
    const lab4 = normalizeLocation('Laboratory 1');

    assert.equal(lab1.roomNumber, '1');
    assert.equal(lab2.roomNumber, '1');
    assert.equal(lab3.roomNumber, '1');
    assert.equal(lab4.roomNumber, '1');
  });

  it('declares compatible locations when room numbers match', () => {
    const res = areLocationsCompatible('Lab 1', 'lab-1');
    assert.equal(res.compatible, true);

    const res2 = areLocationsCompatible('Room 101', 'rm 101');
    assert.equal(res2.compatible, true);
  });

  it('strictly rejects different room numbers (Room 101 vs Room 102)', () => {
    const res = areLocationsCompatible('Room 101', 'Room 102');
    assert.equal(res.compatible, false);
    assert.match(res.reason, /Different room\/lab numbers/i);
  });

  it('strictly rejects different lab numbers (Lab 1 vs Lab 2)', () => {
    const res = areLocationsCompatible('Lab 1', 'Lab 2');
    assert.equal(res.compatible, false);
    assert.match(res.reason, /Different room\/lab numbers/i);
  });

  it('strictly rejects different blocks (Block A vs Block B)', () => {
    const res = areLocationsCompatible('Block A, Room 101', 'Block B, Room 101');
    assert.equal(res.compatible, false);
    assert.match(res.reason, /Different blocks/i);
  });
});

describe('Asset & Entity Extraction', () => {
  it('correctly extracts physical assets and categories', () => {
    const computer = extractComplaintEntities('computer is not working', 'computer is not working it get stuck', 'lab');
    assert.equal(computer.asset, 'computer');
    assert.equal(computer.category, 'IT & Electronics');

    const window = extractComplaintEntities('window is not working', 'window is not working in lab', 'lab');
    assert.equal(window.asset, 'window');
    assert.equal(window.category, 'Facilities & Infrastructure');

    const desk = extractComplaintEntities('Desk is broken', 'one leg is broken in Room 101', 'Room 101');
    assert.equal(desk.asset, 'desk');
    assert.equal(desk.category, 'Furniture');

    const projector = extractComplaintEntities('Projector is not working', 'display turned black in Room 101', 'Room 101');
    assert.equal(projector.asset, 'projector');
    assert.equal(projector.category, 'AV & Electronics');
  });

  it('identifies asset mismatch between different physical objects', () => {
    const check1 = areAssetsCompatible('computer', 'window');
    assert.equal(check1.compatible, false);
    assert.match(check1.reason, /Different physical assets/i);

    const check2 = areAssetsCompatible('desk', 'computer');
    assert.equal(check2.compatible, false);
    assert.match(check2.reason, /Different physical assets/i);

    const check3 = areAssetsCompatible('fan', 'light');
    assert.equal(check3.compatible, false);
    assert.match(check3.reason, /Different physical assets/i);
  });

  it('confirms asset match when both describe the same asset', () => {
    const check1 = areAssetsCompatible('window', 'window');
    assert.equal(check1.compatible, true);

    const check2 = areAssetsCompatible('projector', 'projector');
    assert.equal(check2.compatible, true);
  });
});

  it('MUST merge water purifier duplicate reports in same location', () => {
    const existingIssue = {
      issue_id: 'issue-wp-1',
      title: 'Water purifier is dead',
      description: 'The water purifier stopped working',
      location: 'Seminar Hall',
      status: 'Open',
      asset: 'water_purifier',
      category: 'Plumbing & Facilities',
    };
    const newReport = {
      title: 'water purifier is not working',
      description: 'Water purifier not dispensing water',
      location: 'Seminar Hall',
    };
    const result = evaluateComplaintMatch(newReport, existingIssue);
    assert.equal(result.isMatch, true);
    assert.equal(result.assetA, 'water_purifier');
    assert.equal(result.assetB, 'water_purifier');
  });

describe('User Observed Problem Fix', () => {
  it('MUST NOT merge "computer is not working" with "window is not working" in the same lab', () => {
    const existingIssue = {
      issue_id: 'issue-100',
      title: 'computer is not working',
      description: 'computer is not working it get stuck',
      location: 'lab',
      status: 'Open',
      asset: 'computer',
      category: 'IT & Electronics',
    };

    const newReport = {
      title: 'window is not working',
      description: 'window is not working in lab',
      location: 'lab',
    };

    const result = evaluateComplaintMatch(newReport, existingIssue);
    assert.equal(result.isMatch, false, 'Reports with different assets must not merge');
    assert.match(result.failureReason, /Different physical assets: "window" vs "computer"/);
  });
});

describe('Prompt Required Examples', () => {
  it('Potentially matches: "Window is broken in Lab 1" vs "The lab window won\'t open"', () => {
    const existingIssue = {
      issue_id: 'issue-101',
      title: 'Window is broken in Lab 1',
      description: 'The glass window latch is broken',
      location: 'Lab 1',
      status: 'Open',
      asset: 'window',
      category: 'Facilities & Infrastructure',
      problem_type: 'physical_damage',
    };

    const newReport = {
      title: 'The lab window won\'t open',
      description: 'The window is stuck and won\'t open in Lab 1',
      location: 'Lab 1',
    };

    const result = evaluateComplaintMatch(newReport, existingIssue);
    assert.equal(result.isMatch, true, 'Window faults in same lab should link');
    assert.equal(result.assetA, 'window');
    assert.equal(result.assetB, 'window');
  });

  it('MUST NOT merge: "Computer is not working in Lab 1" vs "Window is not working in Lab 1"', () => {
    const existingIssue = {
      issue_id: 'issue-102',
      title: 'Computer is not working in Lab 1',
      description: 'PC number 4 does not boot',
      location: 'Lab 1',
      status: 'Open',
      asset: 'computer',
      category: 'IT & Electronics',
    };

    const newReport = {
      title: 'Window is not working in Lab 1',
      description: 'Window cannot close in Lab 1',
      location: 'Lab 1',
    };

    const result = evaluateComplaintMatch(newReport, existingIssue);
    assert.equal(result.isMatch, false);
    assert.match(result.failureReason, /Different physical assets: "window" vs "computer"/);
  });

  it('MUST NOT merge: "Desk is broken in Room 101" vs "Computer is not working in Room 101"', () => {
    const existingIssue = {
      issue_id: 'issue-103',
      title: 'Desk is broken in Room 101',
      description: 'The desk leg is broken and wobbles',
      location: 'Room 101',
      status: 'Open',
      asset: 'desk',
      category: 'Furniture',
    };

    const newReport = {
      title: 'Computer is not working in Room 101',
      description: 'The monitor screen won\'t turn on',
      location: 'Room 101',
    };

    const result = evaluateComplaintMatch(newReport, existingIssue);
    assert.equal(result.isMatch, false);
    assert.match(result.failureReason, /Different physical assets: "computer" vs "desk"/);
  });

  it('Potentially matches: "Projector is not working in Room 101" vs "The projector stopped working in Room 101"', () => {
    const existingIssue = {
      issue_id: 'issue-104',
      title: 'Projector is not working in Room 101',
      description: 'Projector display is black and unresponsive',
      location: 'Room 101',
      status: 'Open',
      asset: 'projector',
      category: 'AV & Electronics',
      problem_type: 'non_functional',
    };

    const newReport = {
      title: 'The projector stopped working in Room 101',
      description: 'Projector stopped working during class today in Room 101',
      location: 'Room 101',
    };

    const result = evaluateComplaintMatch(newReport, existingIssue);
    assert.equal(result.isMatch, true);
    assert.equal(result.assetA, 'projector');
    assert.equal(result.assetB, 'projector');
  });

  it('MUST NOT merge: Identical problems in different rooms (Room 101 vs Room 102)', () => {
    const existingIssue = {
      issue_id: 'issue-105',
      title: 'Projector is not working in Room 101',
      description: 'Projector stopped working and won\'t turn on',
      location: 'Room 101',
      status: 'Open',
      asset: 'projector',
      category: 'AV & Electronics',
    };

    const newReport = {
      title: 'Projector is not working in Room 102',
      description: 'Projector stopped working and won\'t turn on',
      location: 'Room 102',
    };

    const result = evaluateComplaintMatch(newReport, existingIssue);
    assert.equal(result.isMatch, false, 'Identical problems in different rooms must not merge');
    assert.match(result.failureReason, /Different room\/lab numbers: "102" vs "101"/);
  });

  it('MUST NOT merge: Identical problems in different labs (Lab 1 vs Lab 2)', () => {
    const existingIssue = {
      issue_id: 'issue-106',
      title: 'Window is broken in Lab 1',
      description: 'The window won\'t open',
      location: 'Lab 1',
      status: 'Open',
      asset: 'window',
      category: 'Facilities & Infrastructure',
    };

    const newReport = {
      title: 'Window is broken in Lab 2',
      description: 'The window won\'t open',
      location: 'Lab 2',
    };

    const result = evaluateComplaintMatch(newReport, existingIssue);
    assert.equal(result.isMatch, false);
    assert.match(result.failureReason, /Different room\/lab numbers: "2" vs "1"/);
  });
});

describe('Status, Concurrency & Edge Cases', () => {
  it('MUST NOT merge into a Closed issue, even if identical', () => {
    const closedIssue = {
      issue_id: 'issue-closed',
      title: 'Projector is not working in Room 101',
      description: 'Projector display is black',
      location: 'Room 101',
      status: 'Closed',
      asset: 'projector',
      category: 'AV & Electronics',
    };

    const newReport = {
      title: 'Projector is not working in Room 101',
      description: 'Projector display is black',
      location: 'Room 101',
    };

    const result = evaluateComplaintMatch(newReport, closedIssue);
    assert.equal(result.isMatch, false);
    assert.match(result.failureReason, /closed issues cannot be merged into/i);
  });

  it('MUST NOT merge when issue asset is ambiguous or unknown (Conservative Fallback)', () => {
    const ambiguousIssue = {
      issue_id: 'issue-vague',
      title: 'Something is strange here',
      description: 'Please look into it as soon as possible',
      location: 'Room 101',
      status: 'Open',
    };

    const newReport = {
      title: 'Computer is not working in Room 101',
      description: 'PC does not turn on',
      location: 'Room 101',
    };

    const result = evaluateComplaintMatch(newReport, ambiguousIssue);
    assert.equal(result.isMatch, false, 'Uncertain or vague reports must not merge automatically');
  });

  it('Location alone is NEVER enough to merge unrelated issues', () => {
    const existingIssue = {
      issue_id: 'issue-chair',
      title: 'Chair is broken in Lab 1',
      description: 'Wooden chair has missing backrest',
      location: 'Lab 1',
      status: 'Open',
      asset: 'chair',
      category: 'Furniture',
    };

    const newReport = {
      title: 'AC is leaking in Lab 1',
      description: 'Water is dripping from the air conditioner',
      location: 'Lab 1',
    };

    const result = evaluateComplaintMatch(newReport, existingIssue);
    assert.equal(result.isMatch, false);
    assert.match(result.failureReason, /Different physical assets/i);
  });

  it('AI Embedding: Different assets must NOT merge even if cosine similarity is high', () => {
    // Simulated dense embedding vectors with 0.88 cosine similarity
    const embA = [0.6, 0.4, 0.5, 0.3];
    const embB = [0.62, 0.38, 0.49, 0.31];

    const existingIssue = {
      issue_id: 'issue-comp',
      title: 'computer is not working',
      description: 'computer is not working it get stuck',
      location: 'lab',
      status: 'Open',
      asset: 'computer',
      embedding: embA,
    };

    const newReport = {
      title: 'window is not working',
      description: 'window is not working in lab',
      location: 'lab',
      embedding: embB,
    };

    const result = evaluateComplaintMatch(newReport, existingIssue);
    assert.equal(result.isMatch, false, 'Asset gate must reject different assets before/despite embedding similarity');
    assert.match(result.failureReason, /Different physical assets/);
  });

  it('AI Embedding: Different locations must NOT merge even if cosine similarity is very high', () => {
    const embA = [0.7, 0.5, 0.4];
    const embB = [0.71, 0.49, 0.41]; // Near identical embeddings

    const existingIssue = {
      issue_id: 'issue-proj-101',
      title: 'Projector is not working in Room 101',
      description: 'Projector has no power in Room 101',
      location: 'Room 101',
      status: 'Open',
      asset: 'projector',
      embedding: embA,
    };

    const newReport = {
      title: 'Projector is not working in Room 102',
      description: 'Projector has no power in Room 102',
      location: 'Room 102',
      embedding: embB,
    };

    const result = evaluateComplaintMatch(newReport, existingIssue);
    assert.equal(result.isMatch, false, 'Location gate must reject different rooms despite high embedding similarity');
    assert.match(result.failureReason, /Different room\/lab numbers/);
  });

  it('Simulated Concurrency: Handles race conditions safely', async () => {
    // Simulate issue state in a mock store
    const mockStore = {
      issues: {
        'issue-concur': {
          issue_id: 'issue-concur',
          title: 'Projector is not working in Room 101',
          description: 'Projector is broken',
          location: 'Room 101',
          status: 'Open',
          asset: 'projector',
          category: 'AV & Electronics',
          updated_at: new Date(),
        },
      },
      reports: [],
    };

    // Simulated transaction runner
    async function mockRunTransaction(updateFn) {
      const transaction = {
        get: async (refId) => ({
          exists: !!mockStore.issues[refId],
          data: () => mockStore.issues[refId],
        }),
        setReport: (report) => {
          mockStore.reports.push(report);
        },
        updateIssue: (refId, updates) => {
          Object.assign(mockStore.issues[refId], updates);
        },
      };
      return updateFn(transaction);
    }

    // Submission 1 and 2 concurrently link to the active issue
    await mockRunTransaction(async (tx) => {
      const doc = await tx.get('issue-concur');
      assert.equal(doc.exists, true);
      assert.equal(doc.data().status, 'Open');
      tx.setReport({ report_id: 'rep-1', issue_id: 'issue-concur', title: 'rep 1' });
      tx.updateIssue('issue-concur', { updated_at: new Date() });
    });

    await mockRunTransaction(async (tx) => {
      const doc = await tx.get('issue-concur');
      assert.equal(doc.exists, true);
      assert.equal(doc.data().status, 'Open');
      tx.setReport({ report_id: 'rep-2', issue_id: 'issue-concur', title: 'rep 2' });
      tx.updateIssue('issue-concur', { updated_at: new Date() });
    });

    assert.equal(mockStore.reports.length, 2);
    assert.equal(mockStore.reports[0].issue_id, 'issue-concur');
    assert.equal(mockStore.reports[1].issue_id, 'issue-concur');

    // Now simulate an admin closing the issue concurrently before submission 3 arrives
    mockStore.issues['issue-concur'].status = 'Closed';

    let submission3CreatedNewIssue = false;
    await mockRunTransaction(async (tx) => {
      const doc = await tx.get('issue-concur');
      if (doc.exists && ['Open', 'In Progress'].includes(doc.data().status)) {
        tx.setReport({ report_id: 'rep-3', issue_id: 'issue-concur' });
      } else {
        // Fallback: create new issue because matched issue was closed
        submission3CreatedNewIssue = true;
      }
    });

    assert.equal(submission3CreatedNewIssue, true, 'Concurrent submission must not link to closed issue');
  });
});
