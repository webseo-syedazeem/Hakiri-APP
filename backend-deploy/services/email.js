const nodemailer = require("nodemailer");

function gmailConfigured() {
  const user = String(process.env.GMAIL_USER || "").trim();
  const pass = String(process.env.GMAIL_APP_PASSWORD || "").trim();
  return Boolean(user && pass);
}

function transporter() {
  const user = String(process.env.GMAIL_USER || "").trim();
  const pass = String(process.env.GMAIL_APP_PASSWORD || "").trim();
  if (!user || !pass) {
    const err = new Error(
      "Gmail is not configured. Set GMAIL_USER and GMAIL_APP_PASSWORD."
    );
    err.statusCode = 503;
    throw err;
  }
  return nodemailer.createTransport({
    service: "gmail",
    auth: { user, pass },
  });
}

async function sendOtpMail({ to, otp, fullName, subject, heading, intro }) {
  const from =
    String(process.env.GMAIL_FROM || "").trim() ||
    String(process.env.GMAIL_USER || "").trim();
  const name = String(fullName || "there").trim() || "there";
  const transport = transporter();

  await transport.sendMail({
    from: `"Hakkiri" <${from}>`,
    to,
    subject,
    text: [
      `Hi ${name},`,
      "",
      intro,
      "",
      `Your code is: ${otp}`,
      "",
      "This code expires in 10 minutes. If you did not request this, you can ignore this email.",
      "",
      "— Hakkiri",
    ].join("\n"),
    html: `
      <div style="font-family:Inter,Arial,sans-serif;max-width:480px;margin:0 auto;padding:24px;color:#0F172A;">
        <h2 style="margin:0 0 12px;font-size:20px;">${heading}</h2>
        <p style="margin:0 0 16px;color:#475569;line-height:1.5;">Hi ${name}, ${intro}</p>
        <div style="font-size:32px;font-weight:800;letter-spacing:8px;background:#F1F5F9;border-radius:12px;padding:16px 20px;text-align:center;color:#2563EB;">
          ${otp}
        </div>
        <p style="margin:16px 0 0;color:#64748B;font-size:13px;line-height:1.45;">
          Expires in <strong>10 minutes</strong>. If you didn’t ask for this, ignore the email.
        </p>
      </div>
    `,
  });
}

/** 6-digit password-reset OTP. */
async function sendPasswordResetOtp({ to, otp, fullName }) {
  return sendOtpMail({
    to,
    otp,
    fullName,
    subject: "Your Hakkiri password reset code",
    heading: "Reset your password",
    intro: "use this code in the Hakkiri app:",
  });
}

/** 6-digit signup email-verification OTP. */
async function sendSignupOtp({ to, otp, fullName }) {
  return sendOtpMail({
    to,
    otp,
    fullName,
    subject: "Verify your Hakkiri email",
    heading: "Verify your email",
    intro: "enter this code in the Hakkiri app to finish creating your account:",
  });
}

module.exports = {
  gmailConfigured,
  sendPasswordResetOtp,
  sendSignupOtp,
};
