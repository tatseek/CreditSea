import crypto from 'node:crypto';
import bcrypt from 'bcryptjs';
import express from 'express';
import { config } from '../config.js';
import { requireAuth } from '../middleware/auth.js';
import { EmailOtpChallenge } from '../models/EmailOtpChallenge.js';
import { sendEmailOtp } from '../services/email.js';

export const emailVerificationRouter = express.Router();
emailVerificationRouter.use(requireAuth);

emailVerificationRouter.post('/request-otp', async (req, res) => {
  const email = String(req.body.email ?? '').trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({ message: 'Enter a valid email address.' });
  }
  const otp = String(crypto.randomInt(100000, 1000000));
  await EmailOtpChallenge.deleteMany({ user: req.user.id, verified: false });
  const challenge = await EmailOtpChallenge.create({
    user: req.user.id,
    email,
    otpHash: await bcrypt.hash(otp, 10),
    expiresAt: new Date(Date.now() + config.otpTtlMinutes * 60_000),
  });
  try {
    await sendEmailOtp(email, otp);
  } catch (error) {
    await challenge.deleteOne();
    return res.status(502).json({ message: error.message });
  }
  res.json({
    message: 'OTP sent to your email.',
    expiresInSeconds: config.otpTtlMinutes * 60,
    ...(config.otpMode === 'development' && !config.resendApiKey
      ? { developmentOtp: otp }
      : {}),
  });
});

emailVerificationRouter.post('/verify-otp', async (req, res) => {
  const email = String(req.body.email ?? '').trim().toLowerCase();
  const challenge = await EmailOtpChallenge.findOne({
    user: req.user.id,
    email,
    verified: false,
  }).sort({ createdAt: -1 });
  if (!challenge || challenge.expiresAt <= new Date()) {
    return res.status(400).json({ message: 'OTP has expired. Request a new one.' });
  }
  if (challenge.attempts >= 5) {
    return res.status(429).json({ message: 'Too many incorrect attempts.' });
  }
  challenge.attempts += 1;
  const matches = await bcrypt.compare(String(req.body.otp ?? ''), challenge.otpHash);
  if (!matches) {
    await challenge.save();
    return res.status(400).json({ message: 'Wrong OTP. Please try again.' });
  }
  challenge.verified = true;
  await challenge.save();
  req.user.email = email;
  req.user.emailVerified = true;
  await req.user.save();
  res.json({ message: 'Email verified successfully.', user: req.user });
});
