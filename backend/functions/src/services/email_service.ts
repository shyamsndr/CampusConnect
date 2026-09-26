import nodemailer from "nodemailer";

interface WelcomeEmailData {
  to: string;
  name: string;
  memberCode: string;
  role: string;
  department: string;
  temporaryPassword: string;
}

/**
 * Sends a welcome email to a newly created CampusConnect user.
 *
 * Email-sending behaviour is controlled by the SMTP_HOST environment variable:
 *   - SMTP_HOST=mock  → logs a redacted confirmation without sending (emulator / CI use)
 *   - SMTP_HOST=fail  → simulates an SMTP failure (used to test rollback paths)
 *   - any real host   → sends the email via the configured SMTP server
 *
 * The temporary password is NEVER logged.
 */
export async function sendWelcomeEmail(data: WelcomeEmailData): Promise<void> {
  const smtpHost = process.env.SMTP_HOST ?? "";
  const smtpPort = Number(process.env.SMTP_PORT ?? "587");
  const smtpUser = process.env.SMTP_USER ?? "";
  const smtpPassword = process.env.SMTP_PASSWORD ?? "";
  const fromEmail = process.env.EMAIL_FROM ?? smtpUser;

  // ── Mock mode: used during local emulator development ─────────────────────
  if (smtpHost === "mock") {
    console.log(
      `[email_service] MOCK – welcome email would be sent to ${data.to} for user ${data.name}`,
    );
    return;
  }

  // ── Fail mode: intentionally throws to exercise the rollback path ──────────
  if (smtpHost === "fail") {
    throw new Error("Simulated SMTP failure for rollback testing.");
  }

  if (!smtpHost || !smtpUser || !smtpPassword || !fromEmail) {
    throw new Error(
      "SMTP configuration is incomplete. " +
      "Ensure SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, and EMAIL_FROM " +
      "are set in environment variables.",
    );
  }

  // ── Mobile app uses email/password auth, not member code ──────────────────
  // Clearly distinguish the login email from the member code identifier.
  const emailBody = `
Hello ${data.name},

Your CampusConnect account has been created successfully.

── Account Details ──────────────────────────────────
  Full Name     : ${data.name}
  Member Code   : ${data.memberCode}
  Role          : ${data.role}
  Department    : ${data.department}
─────────────────────────────────────────────────────

── Login Credentials ────────────────────────────────
  Login Email       : ${data.to}
  Temporary Password: ${data.temporaryPassword}
─────────────────────────────────────────────────────

To log in, use your Login Email and Temporary Password.

For security, please change your password immediately after your first login.

Regards,
CampusConnect Administration
`.trim();

  const transporter = nodemailer.createTransport({
    host: smtpHost,
    port: smtpPort,
    secure: smtpPort === 465,
    auth: {
      user: smtpUser,
      pass: smtpPassword,
    },
  });

  await transporter.sendMail({
    from: `"CampusConnect Administration" <${fromEmail}>`,
    to: data.to,
    subject: "CampusConnect Account Created",
    text: emailBody,
  });
}