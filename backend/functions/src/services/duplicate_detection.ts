/**
 * duplicate_detection.ts
 *
 * Robust, domain-aware duplicate complaint detection for CampusConnect.
 *
 * Implements a multi-tier conservative decision pipeline:
 * 1. Location Normalization & Strict Compatibility Check
 * 2. Physical Asset & Entity Extraction
 * 3. Category & Problem Type / Fault Compatibility
 * 4. Conservative Semantic Similarity (embedding or token-overlap fallback)
 *
 * Guarantees:
 * - Location alone NEVER causes complaints to merge.
 * - Reports describing different assets (e.g. computer vs window, desk vs computer)
 *   NEVER merge, even in the exact same room or lab.
 * - Similar wording across different rooms or locations NEVER merges.
 * - Conservative threshold: when uncertain, reports remain separate as new issues.
 */

export interface NormalizedLocation {
  raw: string;
  canonical: string;
  roomNumber?: string;
  spaceType?: string;
  block?: string;
}

export interface ComplaintEntities {
  asset: string; // e.g. "computer", "window", "desk", "projector", "chair", "fan", "ac", "light", "door", "unknown"
  category: string; // e.g. "IT & Electronics", "Facilities & Infrastructure", "Furniture", "Electrical", "HVAC", "Plumbing", "General"
  faultType: string; // e.g. "non_functional", "physical_damage", "operational_stuck", "electrical_issue", "leaking", "general_defect"
  problemText: string;
  keywords: string[];
}

export interface CandidateIssueData {
  issue_id?: string;
  title: string;
  description: string;
  location: string;
  status: string;
  embedding?: number[] | null;
  normalized_location?: string;
  category?: string;
  asset?: string;
  problem_type?: string;
}

export interface MatchEvaluation {
  isMatch: boolean;
  score: number;
  reasons: string[];
  failureReason?: string;
  assetA: string;
  assetB: string;
  locationA: string;
  locationB: string;
}

// Conservative thresholds
export const CONSERVATIVE_EMBEDDING_THRESHOLD = 0.85;
export const CONSERVATIVE_TOKEN_THRESHOLD = 0.60;

// ── 1. LOCATION NORMALIZATION & MATCHING ──────────────────────────────────────

const STOP_WORDS = new Set([
  "a", "an", "the", "in", "on", "at", "to", "for", "of", "with", "by", "from",
  "is", "are", "was", "were", "it", "its", "get", "gets", "got", "my", "our",
  "this", "that", "there", "and", "or", "but", "so", "be", "been", "being"
]);

export function normalizeLocation(rawLocation: string): NormalizedLocation {
  if (!rawLocation) {
    return { raw: "", canonical: "" };
  }

  const raw = rawLocation.trim();
  let text = raw.toLowerCase().replace(/[,/\\_-]+/g, " ").replace(/\s+/g, " ");

  let roomNumber: string | undefined;
  let spaceType: string | undefined;
  let block: string | undefined;

  // Extract block (e.g., "block a", "block-b", "b block")
  const blockMatch = text.match(/\bblock\s*([a-z0-9]+)\b/) || text.match(/\b([a-z])\s+block\b/);
  if (blockMatch) {
    block = `block ${blockMatch[1]}`;
  }

  // Extract space type and room/number
  // Examples: "lab 1", "lab-01", "room 101", "rm 101", "hall 3", "classroom 204"
  const labMatch = text.match(/\b(lab|laboratory)\s*#?\s*0*(\d+[a-z]?|[a-z])\b/);
  const roomMatch = text.match(/\b(room|rm|classroom|class)\s*#?\s*0*(\d+[a-z]?|[a-z])\b/);
  const hallMatch = text.match(/\b(hall|auditorium|audi)\s*#?\s*0*(\d+[a-z]?|[a-z])\b/);

  if (labMatch) {
    spaceType = "lab";
    roomNumber = labMatch[2];
  } else if (roomMatch) {
    spaceType = "room";
    roomNumber = roomMatch[2];
  } else if (hallMatch) {
    spaceType = "hall";
    roomNumber = hallMatch[2];
  } else {
    // Check for standalone space types without number
    if (/\blab\b|\blaboratory\b/.test(text)) spaceType = "lab";
    else if (/\broom\b|\bclassroom\b/.test(text)) spaceType = "room";
    else if (/\bseminar\s+hall\b/.test(text)) spaceType = "seminar hall";
    else if (/\bhall\b/.test(text)) spaceType = "hall";
    else if (/\blibrary\b/.test(text)) spaceType = "library";
    else if (/\bcafeteria\b|\bcanteen\b/.test(text)) spaceType = "cafeteria";
    else if (/\bauditorium\b|\baudi\b/.test(text)) spaceType = "auditorium";
    else if (/\bgym\b|\bgymnasium\b/.test(text)) spaceType = "gym";
    else if (/\brestroom\b|\bwashroom\b|\btoilet\b/.test(text)) spaceType = "washroom";

    // Check for standalone numbers e.g. "101", "f06", "f 06"
    const standaloneNum = text.match(/\b([a-z]?\d{1,4}[a-z]?)\b/);
    if (standaloneNum && !blockMatch) {
      roomNumber = standaloneNum[1].replace(/^0+/, "");
    }
  }

  // Canonical representation
  const parts: string[] = [];
  if (block) parts.push(block);
  if (spaceType) parts.push(spaceType);
  if (roomNumber) parts.push(roomNumber);

  const canonical = parts.length > 0 ? parts.join(" ") : text.trim();

  return {
    raw,
    canonical,
    roomNumber,
    spaceType,
    block,
  };
}

export function areLocationsCompatible(
  locA: string,
  locB: string
): { compatible: boolean; reason: string } {
  const normA = normalizeLocation(locA);
  const normB = normalizeLocation(locB);

  // If both have block identifiers and they differ
  if (normA.block && normB.block && normA.block !== normB.block) {
    return {
      compatible: false,
      reason: `Different blocks: "${normA.block}" vs "${normB.block}"`
    };
  }

  // If both have space types and they conflict (e.g. library vs cafeteria, lab vs washroom)
  if (normA.spaceType && normB.spaceType && normA.spaceType !== normB.spaceType) {
    // Treat "hall" and "seminar hall" as compatible facility types unless room numbers conflict
    const isHallA = normA.spaceType === "hall" || normA.spaceType === "seminar hall";
    const isHallB = normB.spaceType === "hall" || normB.spaceType === "seminar hall";
    if (isHallA && isHallB) {
      // Compatible hall types
    } else {
      const nonInterchangeable = new Set(["library", "cafeteria", "auditorium", "gym", "washroom", "lab", "seminar hall", "hall"]);
      if (nonInterchangeable.has(normA.spaceType) || nonInterchangeable.has(normB.spaceType)) {
        return {
          compatible: false,
          reason: `Different facility spaces: "${normA.spaceType}" vs "${normB.spaceType}"`
        };
      }
    }
  }

  // If both have room/lab numbers: they MUST match!
  if (normA.roomNumber && normB.roomNumber) {
    if (normA.roomNumber !== normB.roomNumber) {
      return {
        compatible: false,
        reason: `Different room/lab numbers: "${normA.roomNumber}" vs "${normB.roomNumber}"`
      };
    }
  } else if (normA.roomNumber || normB.roomNumber) {
    // One specifies a room number (e.g. "Room 101") and the other does not (e.g. "Main Building")
    // When one is specific and the other is vague, handle conservatively
    // Only allow if spaceType matches and no contradiction, but if one says "Lab 1" and other is just "Room", be conservative
    if (normA.spaceType !== normB.spaceType) {
      return {
        compatible: false,
        reason: `Location specificity mismatch: "${normA.canonical}" vs "${normB.canonical}"`
      };
    }
  }

  // If canonical strings are identical or closely matched
  if (normA.canonical === normB.canonical) {
    return { compatible: true, reason: `Exact canonical match: "${normA.canonical}"` };
  }

  // If both canonical strings exist and neither has an explicit conflict
  if (normA.spaceType && normB.spaceType && normA.spaceType === normB.spaceType && normA.roomNumber === normB.roomNumber) {
    return { compatible: true, reason: `Matching space and room: "${normA.canonical}"` };
  }

  // Fallback: if raw text cleaned matches
  const cleanA = normA.raw.toLowerCase().replace(/[^a-z0-9]/g, "");
  const cleanB = normB.raw.toLowerCase().replace(/[^a-z0-9]/g, "");
  if (cleanA && cleanA === cleanB) {
    return { compatible: true, reason: `Matching sanitized location: "${cleanA}"` };
  }

  return {
    compatible: false,
    reason: `Incompatible locations: "${normA.canonical}" vs "${normB.canonical}"`
  };
}

// ── 2. ASSET & CATEGORY CATALOG ──────────────────────────────────────────────

interface AssetDefinition {
  canonical: string;
  category: string;
  aliases: string[];
  regex: RegExp;
}

const ASSET_CATALOG: AssetDefinition[] = [
  {
    canonical: "computer",
    category: "IT & Electronics",
    aliases: ["computer", "pc", "desktop", "laptop", "monitor", "cpu", "system", "workstation", "mouse", "keyboard", "terminal"],
    regex: /\b(computers?|pc|pcs|desktops?|laptops?|monitors?|cpus?|systems?|workstations?|mouse|keyboards?|terminals?)\b/i,
  },
  {
    canonical: "projector",
    category: "AV & Electronics",
    aliases: ["projector", "beamer", "projection screen", "av projector"],
    regex: /\b(projectors?|beamers?|av\s+projector|overhead\s+projector)\b/i,
  },
  {
    canonical: "window",
    category: "Facilities & Infrastructure",
    aliases: ["window", "windowpane", "casement", "sash", "glass window"],
    regex: /\b(windows?|windowpanes?|window\s+panes?|window\s+sill)\b/i,
  },
  {
    canonical: "desk",
    category: "Furniture",
    aliases: ["desk", "table", "bench", "workstation table", "study table"],
    regex: /\b(desks?|tables?|benches?|study\s+table|lab\s+bench)\b/i,
  },
  {
    canonical: "chair",
    category: "Furniture",
    aliases: ["chair", "seat", "stool", "bench seat"],
    regex: /\b(chairs?|seats?|stools?)\b/i,
  },
  {
    canonical: "air_conditioner",
    category: "HVAC & Electrical",
    aliases: ["ac", "air conditioner", "air conditioning", "aircon", "hvac", "cooling unit"],
    regex: /\b(a\/?c|air\s*conditioners?|air\s*conditioning|aircon|hvac)\b/i,
  },
  {
    canonical: "fan",
    category: "Electrical",
    aliases: ["fan", "ceiling fan", "exhaust fan"],
    regex: /\b(fans?|ceiling\s+fan|exhaust\s+fan)\b/i,
  },
  {
    canonical: "light",
    category: "Electrical",
    aliases: ["light", "bulb", "tube light", "tubelight", "lamp", "lighting"],
    regex: /\b(lights?|bulbs?|tube\s*lights?|tubelights?|lamps?|lighting)\b/i,
  },
  {
    canonical: "door",
    category: "Facilities & Infrastructure",
    aliases: ["door", "lock", "handle", "doorknob", "hinge", "latch"],
    regex: /\b(doors?|door\s*locks?|handles?|doorknobs?|latches?|hinges?)\b/i,
  },
  {
    canonical: "board",
    category: "Furniture & Classroom",
    aliases: ["board", "whiteboard", "blackboard", "chalkboard", "smartboard"],
    regex: /\b(white\s*boards?|black\s*boards?|chalk\s*boards?|smart\s*boards?)\b/i,
  },
  {
    canonical: "printer",
    category: "IT & Office",
    aliases: ["printer", "scanner", "photocopier", "xerox"],
    regex: /\b(printers?|scanners?|photocopiers?|xerox)\b/i,
  },
  {
    canonical: "power_socket",
    category: "Electrical",
    aliases: ["socket", "outlet", "plug", "power strip", "switchboard", "switch"],
    regex: /\b(sockets?|outlets?|plugs?|power\s+strips?|switch\s*boards?)\b/i,
  },
  {
    canonical: "water_purifier",
    category: "Plumbing & Facilities",
    aliases: ["water purifier", "purifier", "water filter", "ro water", "ro purifier", "aqua guard", "aquaguard", "drinking water machine", "water dispenser"],
    regex: /\b(water\s*purifiers?|purifiers?|water\s*filters?|ro\s*purifiers?|ro\s*water|aqua\s*guards?|aquaguard|water\s*dispensers?)\b/i,
  },
  {
    canonical: "plumbing",
    category: "Plumbing & Facilities",
    aliases: ["tap", "faucet", "sink", "pipe", "drain", "water cooler", "toilet", "washroom tap"],
    regex: /\b(taps?|faucets?|sinks?|pipes?|drains?|flush|toilets?|water\s+coolers?)\b/i,
  },
  {
    canonical: "network",
    category: "IT & Network",
    aliases: ["wifi", "wi-fi", "internet", "ethernet", "lan", "router", "network"],
    regex: /\b(wi-?fi|internet|ethernet|lan|routers?|networks?)\b/i,
  },
];

// ── 3. FAULT TYPE CLASSIFIER ──────────────────────────────────────────────────

function classifyFaultType(combinedText: string): string {
  const t = combinedText.toLowerCase();

  if (/\b(won'?t\s+open|cannot\s+open|can'?t\s+open|won'?t\s+close|stuck|jammed|freez|hang|get\s+stuck)\b/i.test(t)) {
    return "operational_stuck";
  }
  if (/\b(broken|crack|damage|shatter|bent|snapped|torn|fallen)\b/i.test(t)) {
    return "physical_damage";
  }
  if (/\b(not\s+working|stopped\s+working|doesn'?t\s+work|malfunction|dead|shut\s+down|failed|unresponsive)\b/i.test(t)) {
    return "non_functional";
  }
  if (/\b(leak|dripping|overflow|flooding)\b/i.test(t)) {
    return "leaking";
  }
  if (/\b(no\s+power|spark|flicker|tripped|short\s+circuit)\b/i.test(t)) {
    return "electrical_issue";
  }
  if (/\b(no\s+internet|disconnected|can'?t\s+connect|slow)\b/i.test(t)) {
    return "connectivity";
  }
  return "general_defect";
}

// ── 4. ENTITY EXTRACTION ──────────────────────────────────────────────────────

export function extractComplaintEntities(
  title: string,
  description: string,
  location?: string
): ComplaintEntities {
  const combined = `${title} ${description}`.trim();
  const lowerCombined = combined.toLowerCase();

  // Find asset match
  let detectedAsset: AssetDefinition | undefined;
  for (const assetDef of ASSET_CATALOG) {
    if (assetDef.regex.test(lowerCombined)) {
      detectedAsset = assetDef;
      break;
    }
  }

  // Tokenize keywords (excluding stopwords and location terms)
  const locTokens = location
    ? location.toLowerCase().replace(/[^a-z0-9]/g, " ").split(/\s+/)
    : [];
  const locTokenSet = new Set(locTokens.filter((w) => w.length > 0));

  const words = lowerCombined
    .replace(/[^a-z0-9]/g, " ")
    .split(/\s+/)
    .filter((w) => w.length > 2 && !STOP_WORDS.has(w) && !locTokenSet.has(w));

  const keywords = Array.from(new Set(words));
  const faultType = classifyFaultType(combined);

  return {
    asset: detectedAsset ? detectedAsset.canonical : "unknown",
    category: detectedAsset ? detectedAsset.category : "General",
    faultType,
    problemText: combined,
    keywords,
  };
}

export function areAssetsCompatible(
  assetA: string,
  assetB: string
): { compatible: boolean; reason: string } {
  // If both are recognized assets
  if (assetA !== "unknown" && assetB !== "unknown") {
    if (assetA !== assetB) {
      return {
        compatible: false,
        reason: `Different physical assets: "${assetA}" vs "${assetB}"`
      };
    }
    return {
      compatible: true,
      reason: `Matching asset: "${assetA}"`
    };
  }

    // If one or both assets are unknown:
    // If both are unknown, allow compatibility based on other checks.
    // If only one is unknown, treat as compatible and defer to later checks.
    if (assetA === "unknown" && assetB === "unknown") {
      return {
        compatible: true,
        reason: `Both assets unknown, proceeding to other similarity checks`
      };
    }
    // One asset known, the other unknown – allow further checks (similarity, fault, etc.)
    if (assetA === "unknown" || assetB === "unknown") {
      return {
        compatible: true,
        reason: `One asset unknown ("${assetA}" vs "${assetB}"), deferring to other checks`
      };
    }
    // Otherwise, assets are known but different – reject.
    return {
      compatible: false,
      reason: `Asset identification uncertain ("${assetA}" vs "${assetB}"). Remaining separate.`
    };
}

export function areFaultsCompatible(
  faultA: string,
  faultB: string,
  asset: string
): boolean {
  if (faultA === faultB) return true;

  // Compatible fault clusters:
  // For windows/doors: "physical_damage" ("broken") and "operational_stuck" ("won't open") are compatible
  if (asset === "window" || asset === "door") {
    const windowFaults = new Set(["physical_damage", "operational_stuck", "non_functional"]);
    if (windowFaults.has(faultA) && windowFaults.has(faultB)) return true;
  }

  // For electronics: "non_functional" ("not working") and "operational_stuck" ("get stuck") are compatible
  if (asset === "computer" || asset === "projector" || asset === "printer") {
    const techFaults = new Set(["non_functional", "operational_stuck", "general_defect"]);
    if (techFaults.has(faultA) && techFaults.has(faultB)) return true;
  }

  // For furniture: "physical_damage" and "general_defect"
  if (asset === "desk" || asset === "chair" || asset === "board") {
    const furnFaults = new Set(["physical_damage", "general_defect", "non_functional"]);
    if (furnFaults.has(faultA) && furnFaults.has(faultB)) return true;
  }

  // If both describe generic defects or non-functional states
  const generalSet = new Set(["non_functional", "general_defect"]);
  if (generalSet.has(faultA) && generalSet.has(faultB)) return true;

  return false;
}

// ── 5. SIMILARITY UTILITIES ──────────────────────────────────────────────────

export function cosineSimilarity(vecA: number[], vecB: number[]): number {
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

export function computeTokenSimilarity(keywordsA: string[], keywordsB: string[]): number {
  if (keywordsA.length === 0 || keywordsB.length === 0) return 0;
  const setA = new Set(keywordsA);
  const setB = new Set(keywordsB);

  let intersection = 0;
  for (const k of setA) {
    if (setB.has(k)) intersection++;
  }

  const minLen = Math.min(setA.size, setB.size);
  if (minLen === 0) return 0;

  // Compute Overlap Coefficient and Dice Coefficient
  const overlap = intersection / minLen;
  const dice = (2 * intersection) / (setA.size + setB.size);

  return Math.max(overlap, dice);
}

// ── 6. MASTER EVALUATOR ──────────────────────────────────────────────────────

export interface NewComplaintInput {
  title: string;
  description: string;
  location: string;
  embedding?: number[] | null;
}

export function evaluateComplaintMatch(
  newComplaint: NewComplaintInput,
  candidateIssue: CandidateIssueData
): MatchEvaluation {
  const reasons: string[] = [];

  // Gate 1: Active status verification
  if (!["Open", "In Progress"].includes(candidateIssue.status)) {
    return {
      isMatch: false,
      score: 0,
      reasons,
      failureReason: `Candidate issue is ${candidateIssue.status}; closed issues cannot be merged into.`,
      assetA: "",
      assetB: "",
      locationA: newComplaint.location,
      locationB: candidateIssue.location,
    };
  }

  // Gate 2: Location Compatibility (Strict prerequisite)
  const locCheck = areLocationsCompatible(newComplaint.location, candidateIssue.location);
  if (!locCheck.compatible) {
    return {
      isMatch: false,
      score: 0,
      reasons,
      failureReason: locCheck.reason,
      assetA: "",
      assetB: "",
      locationA: newComplaint.location,
      locationB: candidateIssue.location,
    };
  }
  reasons.push(`Location compatible: ${locCheck.reason}`);

  // Gate 3: Asset & Entity Extraction
  const entitiesA = extractComplaintEntities(newComplaint.title, newComplaint.description, newComplaint.location);

  // Use cached candidate asset if present, or extract from candidate text
  const candidateAsset = candidateIssue.asset && candidateIssue.asset !== "unknown"
    ? candidateIssue.asset
    : extractComplaintEntities(candidateIssue.title, candidateIssue.description, candidateIssue.location).asset;

  const candidateCategory = candidateIssue.category || extractComplaintEntities(candidateIssue.title, candidateIssue.description, candidateIssue.location).category;
  const candidateFault = candidateIssue.problem_type || extractComplaintEntities(candidateIssue.title, candidateIssue.description, candidateIssue.location).faultType;
  const candidateEntities = extractComplaintEntities(candidateIssue.title, candidateIssue.description, candidateIssue.location);

  const assetCheck = areAssetsCompatible(entitiesA.asset, candidateAsset);
  if (!assetCheck.compatible) {
    return {
      isMatch: false,
      score: 0,
      reasons,
      failureReason: assetCheck.reason,
      assetA: entitiesA.asset,
      assetB: candidateAsset,
      locationA: newComplaint.location,
      locationB: candidateIssue.location,
    };
  }
  reasons.push(`Asset compatible: ${assetCheck.reason}`);

  // Gate 4: Category Compatibility
  if (entitiesA.category !== candidateCategory && entitiesA.category !== "General" && candidateCategory !== "General") {
    return {
      isMatch: false,
      score: 0,
      reasons,
      failureReason: `Category conflict: "${entitiesA.category}" vs "${candidateCategory}"`,
      assetA: entitiesA.asset,
      assetB: candidateAsset,
      locationA: newComplaint.location,
      locationB: candidateIssue.location,
    };
  }

  // Gate 5: Fault Compatibility
  if (!areFaultsCompatible(entitiesA.faultType, candidateFault, entitiesA.asset)) {
    return {
      isMatch: false,
      score: 0,
      reasons,
      failureReason: `Fault conflict for ${entitiesA.asset}: "${entitiesA.faultType}" vs "${candidateFault}"`,
      assetA: entitiesA.asset,
      assetB: candidateAsset,
      locationA: newComplaint.location,
      locationB: candidateIssue.location,
    };
  }
  reasons.push(`Fault types compatible: "${entitiesA.faultType}" ~ "${candidateFault}"`);

  // Gate 6: Conservative Similarity Check
  let similarityScore = 0;
  let passedSimilarity = false;

  if (
    newComplaint.embedding &&
    Array.isArray(newComplaint.embedding) &&
    candidateIssue.embedding &&
    Array.isArray(candidateIssue.embedding)
  ) {
    similarityScore = cosineSimilarity(newComplaint.embedding, candidateIssue.embedding);
    reasons.push(`Cosine similarity: ${similarityScore.toFixed(4)} (threshold: ${CONSERVATIVE_EMBEDDING_THRESHOLD})`);
    if (similarityScore >= CONSERVATIVE_EMBEDDING_THRESHOLD) {
      passedSimilarity = true;
    }
  } else {
    // Fallback: token/keyword overlap
    const tokenSim = computeTokenSimilarity(entitiesA.keywords, candidateEntities.keywords);
    similarityScore = tokenSim;
    reasons.push(`Token overlap similarity: ${tokenSim.toFixed(4)} (threshold: 0.20)`);
    // When asset, category, fault type, and location have ALL strictly matched:
    // Sharing the asset or key problem terms (tokenSim >= 0.20) confirms duplicate issue
    if (tokenSim >= 0.20) {
      passedSimilarity = true;
    }
  }

  if (!passedSimilarity) {
    return {
      isMatch: false,
      score: similarityScore,
      reasons,
      failureReason: `Similarity score ${similarityScore.toFixed(4)} below conservative threshold.`,
      assetA: entitiesA.asset,
      assetB: candidateAsset,
      locationA: newComplaint.location,
      locationB: candidateIssue.location,
    };
  }

  return {
    isMatch: true,
    score: similarityScore,
    reasons,
    assetA: entitiesA.asset,
    assetB: candidateAsset,
    locationA: newComplaint.location,
    locationB: candidateIssue.location,
  };
}
