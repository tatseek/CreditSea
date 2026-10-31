import { Resend } from 'resend';
import { config } from '../config.js';

export async function sendEmailOtp(email, otp) {
  if (!config.resendApiKey) {
    if (config.otpMode === 'development') {
      console.info(`[DEV EMAIL OTP] ${email}: ${otp}`);
      return;
    }
    throw new Error('Email delivery is not configured.');
  }

  const resend = new Resend(config.resendApiKey);
  const { error } = await resend.emails.send({
    from: config.emailFrom,
    to: email,
    subject: 'Your CreditSea verification code',
    html: `
      <div style="font-family:Arial,sans-serif;max-width:520px;margin:auto">
        <h2>Verify your CreditSea email</h2>
        <p>Use this one-time code to verify your email address:</p>
        <p style="font-size:32px;font-weight:700;letter-spacing:8px">${otp}</p>
        <p>This code expires in ${config.otpTtlMinutes} minutes.</p>
        <p>If you did not request this code, you can ignore this email.</p>
      </div>
    `,
  });
  if (error) throw new Error(error.message ?? 'Unable to send verification email.');
}
