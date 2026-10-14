/**
 * test_priority_scoring.mjs
 *
 * Automated test suite for CampusConnect automatic, rule-based complaint priority scoring:
 *
 * 1. Automatic safety keyword detection:
 *    - Detects electrical hazards ("short circuit", "sparking", "exposed wire") -> High
 *    - Detects structural hazards ("ceiling collapse", "broken glass") -> High
 *    - Detects emergency & danger ("chemical spill", "fire hazard", "gas leak") -> High
 *    - Safe complaint without hazard keywords ("water purifier is dead") -> false
 * 2. Formula verification:
 *    - (reporterCount * 10) + (min(elapsedDays, 30) * 2) + (safetyRisk ? 50 : 0)
 * 3. Priority thresholds:
 *    - Low: score < 20
 *    - Medium: 20 <= score < 50
 *    - High: safetyRisk == true OR score >= 50
 * 4. Closed complaints elapsed time freezing via closedAt
 * 5. Distinct reporter scaling
 * 6. Day 30 capping
 */

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  calculatePriorityScore,
  detectSafetyRisk,
} from '../functions/lib/services/complaint_service.js';

describe('Automatic Rule-Based Priority & Safety Detection', () => {
  const MS_PER_DAY = 1000 * 60 * 60 * 24;

  describe('detectSafetyRisk Keyword Matching', () => {
    it('detects electrical hazards', () => {
      assert.equal(detectSafetyRisk('There is a short circuit in the switchboard'), true);
      assert.equal(detectSafetyRisk('Sparking observed near computer terminal'), true);
      assert.equal(detectSafetyRisk('Exposed wire dangling from wall'), true);
      assert.equal(detectSafetyRisk('Live wires in room 101'), true);
    });

    it('detects fire, gas, and chemical hazards', () => {
      assert.equal(detectSafetyRisk('Fire alarm triggered and smoke coming from lab'), true);
      assert.equal(detectSafetyRisk('Suspected gas leak in chemistry department'), true);
      assert.equal(detectSafetyRisk('Chemical spill on floor in lab 2'), true);
    });

    it('detects structural and physical injury hazards', () => {
      assert.equal(detectSafetyRisk('Ceiling collapsed after heavy rain'), true);
      assert.equal(detectSafetyRisk('Broken glass scattered on classroom floor'), true);
      assert.equal(detectSafetyRisk('Dangerous emergency situation near stairs'), true);
    });

    it('returns false for normal non-hazardous complaints', () => {
      assert.equal(detectSafetyRisk('water purifier is dead in seminar hall'), false);
      assert.equal(detectSafetyRisk('projector is not working in room 101'), false);
      assert.equal(detectSafetyRisk('computer is slow and getting stuck'), false);
      assert.equal(detectSafetyRisk('desk drawer is jammed'), false);
    });
  });

  describe('Priority Scoring & Thresholds', () => {
    it('1. reporter_count=1, elapsed=0d, no safety -> Score=10 -> Low', () => {
      const now = new Date('2026-10-14T12:00:00Z');
      const createdAt = new Date('2026-10-14T12:00:00Z');

      const result = calculatePriorityScore({
        reporterCount: 1,
        createdAt,
        safetyRisk: false,
        now,
      });

      assert.equal(result.score, 10);
      assert.equal(result.priority, 'Low');
      assert.equal(result.safetyRisk, false);
    });

    it('2. Safety keyword detected immediately triggers High priority (+50 pts)', () => {
      const now = new Date('2026-10-14T12:00:00Z');
      const createdAt = new Date('2026-10-14T12:00:00Z');

      const result = calculatePriorityScore({
        reporterCount: 1,
        createdAt,
        safetyRisk: true,
        now,
      });

      assert.equal(result.score, 60); // 10 + 0 + 50
      assert.equal(result.priority, 'High');
      assert.equal(result.safetyRisk, true);
    });

    it('3. reporter_count=2, elapsed=0d -> Score=20 -> Medium (exact threshold)', () => {
      const now = new Date('2026-10-14T12:00:00Z');
      const createdAt = new Date('2026-10-14T12:00:00Z');

      const result = calculatePriorityScore({
        reporterCount: 2,
        createdAt,
        safetyRisk: false,
        now,
      });

      assert.equal(result.score, 20);
      assert.equal(result.priority, 'Medium');
    });

    it('4. reporter_count=1, elapsed=5d -> Score=10 + 10 = 20 -> Medium', () => {
      const now = new Date('2026-10-14T12:00:00Z');
      const createdAt = new Date(now.getTime() - (5 * MS_PER_DAY));

      const result = calculatePriorityScore({
        reporterCount: 1,
        createdAt,
        safetyRisk: false,
        now,
      });

      assert.equal(result.score, 20);
      assert.equal(result.priority, 'Medium');
    });

    it('5. reporter_count=5, elapsed=0d -> Score=50 -> High (exact threshold)', () => {
      const now = new Date('2026-10-14T12:00:00Z');
      const createdAt = new Date('2026-10-14T12:00:00Z');

      const result = calculatePriorityScore({
        reporterCount: 5,
        createdAt,
        safetyRisk: false,
        now,
      });

      assert.equal(result.score, 50);
      assert.equal(result.priority, 'High');
    });

    it('6. reporter_count=1, elapsed=20d -> Score=10 + 40 = 50 -> High', () => {
      const now = new Date('2026-10-14T12:00:00Z');
      const createdAt = new Date(now.getTime() - (20 * MS_PER_DAY));

      const result = calculatePriorityScore({
        reporterCount: 1,
        createdAt,
        safetyRisk: false,
        now,
      });

      assert.equal(result.score, 50);
      assert.equal(result.priority, 'High');
    });

    it('7. Boundaries: score 19 -> Low, score 49 -> Medium', () => {
      const now = new Date('2026-10-14T12:00:00Z');
      // 1 reporter (10 pts) + 4 days (8 pts) = 18 pts -> Low
      const r18 = calculatePriorityScore({
        reporterCount: 1,
        createdAt: new Date(now.getTime() - (4 * MS_PER_DAY)),
        safetyRisk: false,
        now,
      });
      assert.equal(r18.score, 18);
      assert.equal(r18.priority, 'Low');

      // 3 reporters (30 pts) + 9 days (18 pts) = 48 pts -> Medium
      const r48 = calculatePriorityScore({
        reporterCount: 3,
        createdAt: new Date(now.getTime() - (9 * MS_PER_DAY)),
        safetyRisk: false,
        now,
      });
      assert.equal(r48.score, 48);
      assert.equal(r48.priority, 'Medium');
    });

    it('8. Elapsed days capped at 30 days (day 60 produces same score as day 30)', () => {
      const now = new Date('2026-10-14T12:00:00Z');
      const d30 = new Date(now.getTime() - (30 * MS_PER_DAY));
      const d60 = new Date(now.getTime() - (60 * MS_PER_DAY));

      const res30 = calculatePriorityScore({ reporterCount: 1, createdAt: d30, safetyRisk: false, now });
      const res60 = calculatePriorityScore({ reporterCount: 1, createdAt: d60, safetyRisk: false, now });

      assert.equal(res30.score, 70); // 10 + 60
      assert.equal(res60.score, 70); // capped at 30 days
      assert.equal(res60.score, res30.score);
      assert.equal(res60.priority, 'High');
    });

    it('9. Closed complaint: elapsed time freezes at closedAt, preventing escalation', () => {
      const createdAt = new Date('2026-10-01T12:00:00Z');
      const closedAt = new Date('2026-10-03T12:00:00Z'); // closed 2 days after creation -> 4 pts
      const futureNow = new Date('2026-11-01T12:00:00Z'); // 31 days later

      const res = calculatePriorityScore({
        reporterCount: 1,
        createdAt,
        safetyRisk: false,
        closedAt,
        now: futureNow,
      });

      // 10 + 4 = 14 pts -> still Low, does not escalate to High despite future now
      assert.equal(res.score, 14);
      assert.equal(res.priority, 'Low');
    });
  });
});
