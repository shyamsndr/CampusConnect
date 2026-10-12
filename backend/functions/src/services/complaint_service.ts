import { HttpsError } from "firebase-functions/v2/https";
import { adminDb } from "../config/firebase";
import { FieldValue } from "firebase-admin/firestore";
import { GoogleGenAI } from "@google/genai";
import { defineString } from "firebase-functions/params";

const geminiApiKey = defineString("GEMINI_API_KEY");

// Threshold for semantic similarity. 0.8 is a reasonable starting point for text-embedding-004
const SIMILARITY_THRESHOLD = 0.8;

function cosineSimilarity(vecA: number[], vecB: number[]): number {
  if (vecA.length !== vecB.length) return 0;
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;
  for (let i = 0; i < vecA.length; i++) {
    dotProduct += vecA[i] * vecB[i];
    normA += vecA[i] * vecA[i];
    normB += vecB[i] * vecB[i];
  }
  if (normA === 0 || normB === 0) return 0;
  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

export async function processNewComplaint(data: any, uid: string) {
  const { title, description, location, imageUrl } = data;

  if (!title || !description || !location) {
    throw new HttpsError("invalid-argument", "Title, description, and location are required.");
  }

  let newEmbedding: number[] | null = null;

  // 1. Generate embedding for the new complaint
  try {
    const ai = new GoogleGenAI({ apiKey: geminiApiKey.value() });
    const textToEmbed = `Title: ${title}\nDescription: ${description}\nLocation: ${location}`;
    
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
    console.error("[processNewComplaint] AI Embedding failed:", errMessage);
    // Fallback: continue without an embedding, which will force a new issue creation
  }

  let matchedIssueId: string | null = null;

  // 2. Find similar issues if embedding succeeded
  if (newEmbedding) {
    try {
      const activeIssuesSnapshot = await adminDb
        .collection("ISSUES")
        .where("status", "in", ["Open", "In Progress"])
        .get();

      const candidateIds = activeIssuesSnapshot.docs.map((doc) => doc.id);
      console.log(`[processNewComplaint] Retrieved ${candidateIds.length} candidate issues:`, candidateIds);

      let bestMatchId: string | null = null;
      let highestSimilarity = 0;

      for (const doc of activeIssuesSnapshot.docs) {
        const issueData = doc.data();
        if (issueData.embedding && Array.isArray(issueData.embedding)) {
          const similarity = cosineSimilarity(newEmbedding, issueData.embedding);
          console.log(`[processNewComplaint] Candidate [${doc.id}] "${issueData.title}" similarity: ${similarity.toFixed(4)} (threshold: ${SIMILARITY_THRESHOLD})`);
          if (similarity > highestSimilarity) {
            highestSimilarity = similarity;
            bestMatchId = doc.id;
          }
        } else {
          console.log(`[processNewComplaint] Candidate [${doc.id}] "${issueData.title}" has no embedding, skipping`);
        }
      }

      console.log(`[processNewComplaint] Best match candidate: ${bestMatchId ?? "none"}, highest similarity: ${highestSimilarity.toFixed(4)}, threshold: ${SIMILARITY_THRESHOLD}`);
      
      if (highestSimilarity >= SIMILARITY_THRESHOLD && bestMatchId) {
        matchedIssueId = bestMatchId;
      }
    } catch (error) {
      const errMessage = error instanceof Error ? error.message : String(error);
      console.error("[processNewComplaint] Error searching for duplicates:", errMessage);
      // Fallback: create new issue
    }
  } else {
    console.warn("[processNewComplaint] Skipping candidate search: no embedding available for new complaint");
  }

  console.log(`[processNewComplaint] Decision: ${matchedIssueId ? `LINK_TO_EXISTING (${matchedIssueId})` : "CREATE_NEW_PRIMARY_ISSUE"}`);

  // 3. Perform Firestore writes using a Batch
  const batch = adminDb.batch();
  const now = FieldValue.serverTimestamp();

  const reportRef = adminDb.collection("ISSUE_REPORTS").doc();
  const reportId = reportRef.id;

  if (matchedIssueId) {
    console.log(`[processNewComplaint] Confident duplicate found. Linking to issue: ${matchedIssueId}`);
    
    // Create ISSUE_REPORT linked to the matched issue
    batch.set(reportRef, {
      report_id: reportId,
      issue_id: matchedIssueId,
      user_id: uid,
      title: title,
      description: description,
      location: location,
      image_url: imageUrl || null,
      created_at: now,
    });
    
    // We DO NOT update the primary issue's status or create a new status history entry,
    // as requested by the prompt.

  } else {
    console.log("[processNewComplaint] No duplicate found. Creating new primary issue.");
    
    const issueRef = adminDb.collection("ISSUES").doc();
    const issueId = issueRef.id;
    const historyRef = adminDb.collection("ISSUE_STATUS_HISTORY").doc();
    const historyId = historyRef.id;

    // Create primary ISSUE
    batch.set(issueRef, {
      issue_id: issueId,
      title: title,
      description: description,
      location: location,
      primary_image_url: imageUrl || null,
      primary_report_id: reportId,
      primary_reporter_id: uid,
      status: "Open",
      priority: "Medium",
      created_at: now,
      updated_at: now,
      closed_at: null,
      embedding: newEmbedding || null, // Store embedding for future comparisons
    });

    // Create initial ISSUE_REPORT
    batch.set(reportRef, {
      report_id: reportId,
      issue_id: issueId,
      user_id: uid,
      title: title,
      description: description,
      location: location,
      image_url: imageUrl || null,
      created_at: now,
    });

    // Create ISSUE_STATUS_HISTORY
    batch.set(historyRef, {
      history_id: historyId,
      issue_id: issueId,
      old_status: null,
      new_status: "Open",
      changed_by: uid,
      changed_at: now,
    });
  }

  await batch.commit();

  return {
    success: true,
    matchedIssueId,
    message: matchedIssueId ? "Added to existing issue." : "New issue created.",
  };
}
