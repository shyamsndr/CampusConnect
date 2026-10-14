import { HttpsError } from "firebase-functions/v2/https";
import { adminDb } from "../config/firebase";
import { FieldValue } from "firebase-admin/firestore";
import { GoogleGenAI } from "@google/genai";
import { defineString } from "firebase-functions/params";
import {
  extractComplaintEntities,
  normalizeLocation,
  evaluateComplaintMatch,
  CandidateIssueData,
} from "./duplicate_detection";

const geminiApiKey = defineString("GEMINI_API_KEY");

// ── Rule-Based Safety Keyword Matcher ─────────────────────────────────────────
const SAFETY_PATTERNS: RegExp[] = [
  /\b(fire|smoke|spark|sparks|sparking|short\s*circuit|burning|explosion|explode|exploding)\b/i,
  /\b(electric\s*shock|exposed\s*wire|exposed\s*wires|live\s*wire|live\s*wires|electrocution)\b/i,
  /\b(ceiling\s*fall|ceiling\s*collapsed?|wall\s*collapsed?|structural\s*damage)\b/i,
  /\b(broken\s*glass|shattered\s*glass|gas\s*leak|chemical\s*spill|flood|flooding)\b/i,
  /\b(danger|dangerous|hazard|hazardous|emergency|injury|injured)\b/i,
];

export function detectSafetyRisk(text: string): boolean {
  if (!text) return false;
  return SAFETY_PATTERNS.some((pattern) => pattern.test(text));
}

export function calculatePriorityScore(params: {
  reporterCount: number;
  createdAt: Date;
  safetyRisk: boolean;
  closedAt?: Date | null;
  now?: Date;
}): { score: number; priority: "Low" | "Medium" | "High"; safetyRisk: boolean } {
  const { reporterCount, createdAt, safetyRisk, closedAt, now = new Date() } = params;

  // Use closedAt if available to freeze elapsed time for closed complaints
  const refDate = closedAt ? closedAt : now;
  const elapsedDays = Math.min(30, Math.max(0, Math.floor((refDate.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24))));

  const score = (reporterCount * 10) + (elapsedDays * 2) + (safetyRisk ? 50 : 0);

  let priority: "Low" | "Medium" | "High";
  if (safetyRisk || score >= 50) {
    priority = "High";
  } else if (score >= 20) {
    priority = "Medium";
  } else {
    priority = "Low";
  }

  return { score, priority, safetyRisk };
}

export async function processNewComplaint(data: any, uid: string) {
  const { title, description, location, imageUrl } = data;

  if (!title || !description || !location) {
    throw new HttpsError("invalid-argument", "Title, description, and location are required.");
  }

  // 1. Extract domain entities, asset, category, fault, and normalized location
  const entities = extractComplaintEntities(title, description, location);
  const normalizedLoc = normalizeLocation(location);

  console.log(`[processNewComplaint] Extracted entities for report by user ${uid}:`, {
    title,
    location,
    normalizedLocation: normalizedLoc.canonical,
    asset: entities.asset,
    category: entities.category,
    faultType: entities.faultType,
  });

  let newEmbedding: number[] | null = null;

  // 2. Generate embedding focused on asset, category, and problem description
  // Note: We exclude raw location string from the embedding to prevent shared location
  // names (e.g. "lab", "room") from falsely inflating semantic similarity across different problems.
  try {
    const ai = new GoogleGenAI({ apiKey: geminiApiKey.value() });
    const textToEmbed = `Asset: ${entities.asset}\nCategory: ${entities.category}\nTitle: ${title}\nDescription: ${description}`;

    const response = await ai.models.embedContent({
      model: "gemini-embedding-001",
      contents: textToEmbed,
    });

    if (response.embeddings && response.embeddings.length > 0) {
      newEmbedding = response.embeddings[0].values ?? null;
      console.log(`[processNewComplaint] Embedding generated successfully (dimensions: ${newEmbedding?.length ?? 0})`);
    } else {
      console.warn("[processNewComplaint] Embedding response contained no embeddings");
    }
  } catch (error) {
    const errMessage = error instanceof Error ? error.message : String(error);
    console.error("[processNewComplaint] AI Embedding failed or skipped:", errMessage);
    // Graceful fallback: continue without an embedding; deterministic entity & token evaluation will be used
  }

  let matchedIssueId: string | null = null;

  // 3. Find duplicate issues among active ("Open", "In Progress") issues
  try {
    const activeIssuesSnapshot = await adminDb
      .collection("ISSUES")
      .where("status", "in", ["Open", "In Progress"])
      .get();

    const candidateDocs = activeIssuesSnapshot.docs;
    console.log(`[processNewComplaint] Evaluating ${candidateDocs.length} active candidate issues`);

    let bestMatchId: string | null = null;
    let highestScore = -1;

    for (const doc of candidateDocs) {
      const issueData = doc.data() as CandidateIssueData;
      const evaluation = evaluateComplaintMatch(
        {
          title,
          description,
          location,
          embedding: newEmbedding,
        },
        issueData
      );

      console.log(
        `[processNewComplaint] Candidate [${doc.id}] "${issueData.title}": isMatch=${evaluation.isMatch}, score=${evaluation.score.toFixed(4)}. Reasons: ${evaluation.reasons.join(" | ")}${evaluation.failureReason ? ` [REJECTED: ${evaluation.failureReason}]` : ""}`
      );

      if (evaluation.isMatch && evaluation.score > highestScore) {
        highestScore = evaluation.score;
        bestMatchId = doc.id;
      }
    }

    if (bestMatchId) {
      matchedIssueId = bestMatchId;
      console.log(`[processNewComplaint] Selected confident match: ${matchedIssueId} (score: ${highestScore.toFixed(4)})`);
    } else {
      console.log("[processNewComplaint] No candidate matched all duplicate criteria. Creating new primary issue.");
    }
  } catch (error) {
    const errMessage = error instanceof Error ? error.message : String(error);
    console.error("[processNewComplaint] Error searching for duplicates:", errMessage);
    // Fallback: create new issue safely
  }

  // 4. Perform Firestore writes using a Transaction for atomic concurrency protection
  const now = FieldValue.serverTimestamp();
  const reportRef = adminDb.collection("ISSUE_REPORTS").doc();
  const reportId = reportRef.id;

  let finalMatchedIssueId: string | null = null;

  await adminDb.runTransaction(async (transaction) => {
    if (matchedIssueId) {
      const issueRef = adminDb.collection("ISSUES").doc(matchedIssueId);
      const issueDoc = await transaction.get(issueRef);

      // Verify the candidate issue still exists and is still Open or In Progress
      if (issueDoc.exists && ["Open", "In Progress"].includes(issueDoc.data()?.status)) {
        finalMatchedIssueId = matchedIssueId;

        // Check if this distinct user already has a report for this issue
        const existingReportsQuery = adminDb
          .collection("ISSUE_REPORTS")
          .where("issue_id", "==", matchedIssueId)
          .where("user_id", "==", uid)
          .limit(1);
        const existingReportsSnap = await transaction.get(existingReportsQuery);
        const isNewReporter = existingReportsSnap.empty;

        // Create ISSUE_REPORT linked to the matched issue
        transaction.set(reportRef, {
          report_id: reportId,
          issue_id: matchedIssueId,
          user_id: uid,
          title: title,
          description: description,
          location: location,
          image_url: imageUrl || null,
          created_at: now,
        });

        // Compute updated priority if reporter count changes
        const issueData = issueDoc.data() || {};
        // Check if this incoming report mentions safety hazards
        const newReportHasSafetyRisk = detectSafetyRisk(`${title} ${description}`);
        const currentSafetyRisk = Boolean(issueData.safety_risk) || newReportHasSafetyRisk;

        const currentReporterCount = typeof issueData.reporter_count === "number" ? issueData.reporter_count : 1;
        const newReporterCount = isNewReporter ? currentReporterCount + 1 : currentReporterCount;
        const createdAtDate = issueData.created_at?.toDate ? issueData.created_at.toDate() : new Date();

        const priorityCalc = calculatePriorityScore({
          reporterCount: newReporterCount,
          createdAt: createdAtDate,
          safetyRisk: currentSafetyRisk,
        });

        const updatePayload: Record<string, any> = {
          updated_at: now,
          priority: priorityCalc.priority,
          safety_risk: currentSafetyRisk,
        };

        if (isNewReporter) {
          updatePayload.reporter_count = FieldValue.increment(1);
        }

        transaction.update(issueRef, updatePayload);

        console.log(`[processNewComplaint] Transactionally linked report ${reportId} to existing issue ${matchedIssueId} (isNewReporter=${isNewReporter}, safetyRisk=${currentSafetyRisk}, newPriority=${priorityCalc.priority})`);
        return;
      } else {
        console.warn(`[processNewComplaint] Matched issue ${matchedIssueId} was closed or deleted concurrently; creating new primary issue`);
      }
    }

    // No matched issue (or candidate closed concurrently) -> create new primary issue
    const issueRef = adminDb.collection("ISSUES").doc();
    const issueId = issueRef.id;
    const historyRef = adminDb.collection("ISSUE_STATUS_HISTORY").doc();
    const historyId = historyRef.id;

    // Detect safety hazards automatically from complaint text
    const initialSafetyRisk = detectSafetyRisk(`${title} ${description}`);

    // Initial priority score for reporter_count=1, elapsed=0, rule-based safetyRisk
    const initialPriorityCalc = calculatePriorityScore({
      reporterCount: 1,
      createdAt: new Date(),
      safetyRisk: initialSafetyRisk,
    });

    transaction.set(issueRef, {
      issue_id: issueId,
      title: title,
      description: description,
      location: location,
      primary_image_url: imageUrl || null,
      primary_report_id: reportId,
      primary_reporter_id: uid,
      status: "Open",
      priority: initialPriorityCalc.priority,
      reporter_count: 1,
      safety_risk: initialSafetyRisk,
      created_at: now,
      updated_at: now,
      closed_at: null,
      embedding: newEmbedding || null,
      // Enriched metadata preserving compatibility
      normalized_location: normalizedLoc.canonical,
      category: entities.category,
      asset: entities.asset,
      problem_type: entities.faultType,
    });

    transaction.set(reportRef, {
      report_id: reportId,
      issue_id: issueId,
      user_id: uid,
      title: title,
      description: description,
      location: location,
      image_url: imageUrl || null,
      created_at: now,
    });

    transaction.set(historyRef, {
      history_id: historyId,
      issue_id: issueId,
      old_status: null,
      new_status: "Open",
      changed_by: uid,
      changed_at: now,
    });

    console.log(`[processNewComplaint] Transactionally created new primary issue ${issueId} with report ${reportId}`);
  });

  return {
    success: true,
    matchedIssueId: finalMatchedIssueId,
    message: finalMatchedIssueId ? "Added to existing issue." : "New issue created.",
  };
}
