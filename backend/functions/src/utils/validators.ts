import {promises as dnsPromises} from "dns";

/**
 * Validates email syntax strictly according to RFC 5321/5322 rules.
 * Rejects malformed addresses, consecutive dots, invalid local or domain parts.
 */
export function validateEmailSyntax(email: string): string | null {
  if (!email || typeof email !== "string") {
    return "Email address is required.";
  }

  const trimmed = email.trim();
  if (trimmed.length === 0) {
    return "Email address is required.";
  }

  // RFC 5321 length limits: max 254 chars total
  if (trimmed.length > 254) {
    return "Invalid email address.";
  }

  const atParts = trimmed.split("@");
  if (atParts.length !== 2) {
    return "Invalid email address.";
  }

  const [localPart, domainPart] = atParts;

  // Local-part checks (RFC 5321: max 64 octets)
  if (localPart.length === 0 || localPart.length > 64) {
    return "Invalid email address.";
  }

  if (
    localPart.startsWith(".") ||
    localPart.endsWith(".") ||
    localPart.includes("..")
  ) {
    return "Invalid email address.";
  }

  const localPartRegex =
    /^[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)*$/;
  if (!localPartRegex.test(localPart)) {
    return "Invalid email address.";
  }

  // Domain-part checks (RFC 1035 / RFC 5321: max 255 octets)
  if (domainPart.length === 0 || domainPart.length > 255) {
    return "Invalid email address.";
  }

  if (
    domainPart.startsWith(".") ||
    domainPart.endsWith(".") ||
    domainPart.includes("..")
  ) {
    return "Invalid email address.";
  }

  const domainLabels = domainPart.split(".");
  if (domainLabels.length < 2) {
    return "Invalid email address.";
  }

  const labelRegex = /^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$/;
  for (const label of domainLabels) {
    if (!labelRegex.test(label)) {
      return "Invalid email address.";
    }
  }

  // TLD must be alphabetic or valid punycode and at least 2 chars long
  const tld = domainLabels[domainLabels.length - 1];
  const tldRegex = /^(?:[a-zA-Z]{2,}|xn--[a-zA-Z0-9]+)$/;
  if (!tldRegex.test(tld)) {
    return "Invalid email address.";
  }

  return null;
}

/**
 * Checks that the email domain has valid mail-routing DNS records where feasible.
 * Queries MX records and falls back to A/AAAA address records (RFC 5321 § 5.1).
 * Detects Null MX (RFC 7505) and non-existent domains.
 */
export async function validateEmailDomainDns(
  email: string,
): Promise<string | null> {
  const atIndex = email.lastIndexOf("@");
  if (atIndex === -1) {
    return "Invalid email address.";
  }
  const domain = email.slice(atIndex + 1).toLowerCase();

  // In test / emulator environments, allow RFC 2606 / RFC 6761 reserved test TLDs
  const isTestOrEmulator =
    process.env.FUNCTIONS_EMULATOR === "true" ||
    process.env.NODE_ENV === "test" ||
    process.env.SMTP_HOST === "mock" ||
    process.env.SMTP_HOST === "fail";

  if (isTestOrEmulator) {
    if (
      domain.endsWith(".test") ||
      domain.endsWith(".example") ||
      domain.endsWith(".invalid") ||
      domain === "localhost"
    ) {
      return null;
    }
  }

  try {
    // 1. Resolve MX records
    let mxRecords: Array<{exchange: string; priority: number}> = [];
    try {
      mxRecords = await dnsPromises.resolveMx(domain);
    } catch (mxErr: unknown) {
      const errCode = (mxErr as {code?: string})?.code;
      if (errCode === "ENOTFOUND" || errCode === "NXDOMAIN") {
        return `The email domain '${domain}' does not exist.`;
      }
      if (errCode === "ENODATA") {
        mxRecords = [];
      } else {
        // Transient network error (e.g. ETIMEOUT, ESERVFAIL)
        console.warn(
          `[validators] Transient DNS MX lookup warning for ${domain}: ${errCode}`,
        );
        return null;
      }
    }

    if (mxRecords && mxRecords.length > 0) {
      // Reject Null MX (RFC 7505: priority 0, exchange "." or empty)
      const validMx = mxRecords.some(
        (r) => r.exchange && r.exchange !== "." && r.exchange.trim().length > 0,
      );
      if (!validMx) {
        return `The domain '${domain}' does not accept email (Null MX configured).`;
      }
      return null;
    }

    // 2. Fallback to A / AAAA records (RFC 5321 § 5.1)
    try {
      const ipv4 = await dnsPromises.resolve4(domain);
      if (ipv4 && ipv4.length > 0) {
        return null;
      }
    } catch (aErr: unknown) {
      const code = (aErr as {code?: string})?.code;
      if (code !== "ENODATA" && code !== "ENOTFOUND" && code !== "NXDOMAIN") {
        console.warn(
          `[validators] Transient DNS A lookup warning for ${domain}: ${code}`,
        );
        return null;
      }
    }

    try {
      const ipv6 = await dnsPromises.resolve6(domain);
      if (ipv6 && ipv6.length > 0) {
        return null;
      }
    } catch (aaaaErr: unknown) {
      const code = (aaaaErr as {code?: string})?.code;
      if (
        code !== "ENODATA" &&
        code !== "ENOTFOUND" &&
        code !== "NXDOMAIN"
      ) {
        console.warn(
          `[validators] Transient DNS AAAA lookup warning for ${domain}: ${code}`,
        );
        return null;
      }
    }

    return `The email domain '${domain}' does not have valid mail-routing DNS records.`;
  } catch (err: unknown) {
    console.warn(`[validators] Unexpected DNS lookup error for ${domain}:`, err);
    return null;
  }
}

export function validateUserData(data: {
  memberCode: string;
  name: string;
  email: string;
  role: string;
  department: string;
  phone: string;
}): string | null {
  if (!data.memberCode.trim()) {
    return "Member code is required.";
  }

  if (!data.name.trim()) {
    return "Full name is required.";
  }

  if (!data.email.trim()) {
    return "Email address is required.";
  }

  if (!data.role.trim()) {
    return "Role is required.";
  }

  if (!data.department.trim()) {
    return "Department is required.";
  }

  if (!data.phone.trim()) {
    return "Phone number is required.";
  }

  if (!["Student", "Staff"].includes(data.role)) {
    return "Invalid role. Allowed roles: Student, Staff.";
  }

  if (!["MCA", "MBA"].includes(data.department)) {
    return "Invalid department. Allowed departments: MCA, MBA.";
  }

  const emailSyntaxError = validateEmailSyntax(data.email);
  if (emailSyntaxError) {
    return emailSyntaxError;
  }

  return null;
}
