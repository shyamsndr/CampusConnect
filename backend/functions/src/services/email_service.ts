import nodemailer from "nodemailer";
import type { Transporter, SendMailOptions } from "nodemailer";

interface WelcomeEmailData {
  to: string;
  name: string;
  memberCode: string;
  role: string;
  department: string;
  temporaryPassword: string;
}


/**
 * Creates a Nodemailer SMTP transporter using environment variables.
 * Never logs SMTP credentials.
 */
function createTransporter(): Transporter {
  const smtpHost = process.env.SMTP_HOST ?? "";
  const smtpPort = Number(process.env.SMTP_PORT ?? "587");
  const smtpUser = process.env.SMTP_USER ?? "";
  const smtpPassword = process.env.SMTP_PASSWORD ?? "";

  if (!smtpHost || !smtpUser || !smtpPassword) {
    throw new Error(
      "SMTP configuration is incomplete. Ensure SMTP_HOST, SMTP_PORT, SMTP_USER, and SMTP_PASSWORD are set.",
    );
  }

  console.log(
    `[email_service] Creating SMTP transport: host=${smtpHost}, port=${smtpPort}`,
  );

  return nodemailer.createTransport({
    host: smtpHost,
    port: smtpPort,
    secure: smtpPort === 465,
    auth: {
      user: smtpUser,
      pass: smtpPassword,
    },
  });
}

function getFromAddress(): string {
  const smtpUser = process.env.SMTP_USER ?? "";
  return process.env.EMAIL_FROM ?? smtpUser;
}

export interface WelcomeEmailResult {
  accepted: boolean;
  messageId?: string;
  response?: string;
}

/**
 * Sends an email and logs safe SMTP submission details.
 * SMTP acceptance does not guarantee inbox delivery or prove that a mailbox exists.
 */
async function sendMailWithLogging(
  transporter: Transporter,
  mailOptions: SendMailOptions,
): Promise<{messageId?: string; response?: string}> {
  const recipient =
    typeof mailOptions.to === "string"
      ? mailOptions.to
      : String(mailOptions.to ?? "");

  try {
    const info = await transporter.sendMail(mailOptions);

    console.log("[email_service] SMTP submission result:", {
      to: recipient,
      messageId: info.messageId,
      accepted: info.accepted,
      rejected: info.rejected,
      smtpResponse: info.response,
    });

    if (Array.isArray(info.rejected) && info.rejected.length > 0) {
      throw new Error(
        `SMTP server rejected recipient(s): ${info.rejected.join(", ")}`,
      );
    }

    console.log(
      `[email_service] Email accepted by SMTP server for ${recipient}. Note: SMTP acceptance indicates transmission to the mail relay only; it does not confirm mailbox existence or final inbox delivery.`,
    );

    return {
      messageId: info.messageId,
      response: info.response,
    };
  } catch (error: unknown) {
    if (error instanceof Error) {
      const smtpError = error as Error & {
        code?: string;
        responseCode?: number;
        response?: string;
        command?: string;
      };

      console.error("[email_service] SMTP error:", {
        to: recipient,
        errorName: smtpError.name,
        errorCode: smtpError.code,
        message: smtpError.message,
        responseCode: smtpError.responseCode,
        smtpResponse: smtpError.response,
        command: smtpError.command,
      });
    } else {
      console.error("[email_service] SMTP error:", String(error));
    }

    throw error;
  }
}

/**
 * Sends a welcome email to a newly created CampusConnect user.
 *
 * Email-sending behaviour is controlled by the SMTP_HOST environment variable:
 *   - SMTP_HOST=mock  → logs a confirmation without sending (emulator / CI use)
 *   - SMTP_HOST=fail  → simulates an SMTP failure (used to test rollback paths)
 *   - any real host   → sends the email via the configured SMTP server
 *
 * The temporary password is NEVER logged.
 */
export async function sendWelcomeEmail(
  data: WelcomeEmailData,
): Promise<WelcomeEmailResult> {
  const smtpHost = process.env.SMTP_HOST ?? "";

  if (smtpHost === "mock") {
    console.log(
      `[email_service] MOCK – welcome email accepted by mock server for ${data.to} (user ${data.name})`,
    );
    return {
      accepted: true,
      messageId: "mock-message-id",
      response: "250 2.0.0 OK (mock)",
    };
  }

  if (smtpHost === "fail") {
    throw new Error("Simulated SMTP failure for rollback testing.");
  }

  const fromEmail = getFromAddress();
  const transporter = createTransporter();

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

Use your login email and temporary password to sign in to CampusConnect. For security, please change your password after your first login.
`.trim();

  const result = await sendMailWithLogging(transporter, {
    from: `"CampusConnect Administration" <${fromEmail}>`,
    to: data.to,
    subject: "CampusConnect Account Created",
    text: emailBody,
  });

  return {
    accepted: true,
    messageId: result.messageId,
    response: result.response,
  };
}