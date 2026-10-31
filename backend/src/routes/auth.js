import crypto from 'node:crypto';
import bcrypt from 'bcryptjs';
import express from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config.js';
import { OtpChallenge } from '../models/OtpChallenge.js';
import { User } from '../models/User.js';

export const authRouter = express.Router();

const normalizeMobile = (value) => String(value ?? '').replace(/\D/g, '').slice(-10);
const signSession = (user) => jwt.sign({}, config.jwtSecret, {
  subject: user.id,
  expiresIn: config.jwtExpiresIn,
});

authRouter.post('/request-otp', async (req, res) => {
  const mobile = normalizeMobile(req.body.mobile);
  if (!/^\d{10}$/.test(mobile)) {
    return res.status(400).json({ message: 'Enter a valid 10-digit mobile number.' });
  }
  const otp = config.otpMode === 'development' && mobile === config.stagingMobile
    ? config.stagingOtp
    : String(crypto.randomInt(1000, 10000));
  await OtpChallenge.deleteMany({ mobile });
  await OtpChallenge.create({
    mobile,
    otpHash: await bcrypt.hash(otp, 10),
    expiresAt: new Date(Date.now() + config.otpTtlMinutes * 60_000),
  });
  // Replace this with an SMS provider adapter in production.
  if (config.otpMode === 'development') console.info(`[DEV OTP] ${mobile}: ${otp}`);
  res.json({
    message: 'OTP sent.',
    expiresInSeconds: config.otpTtlMinutes * 60,
    ...(config.otpMode === 'development' ? { developmentOtp: otp } : {}),
  });
});

authRouter.post('/verify-otp', async (req, res) => {
  const mobile = normalizeMobile(req.body.mobile);
  const challenge = await OtpChallenge.findOne({ mobile, verified: false }).sort({ createdAt: -1 });
  if (!challenge || challenge.expiresAt <= new Date()) {
    return res.status(400).json({ message: 'OTP has expired. Request a new one.' });
  }
  if (challenge.attempts >= 5) {
    return res.status(429).json({ message: 'Too many OTP attempts.' });
  }
  challenge.attempts += 1;
  if (!(await bcrypt.compare(String(req.body.otp ?? ''), challenge.otpHash))) {
    await challenge.save();
    return res.status(400).json({ message: 'Invalid OTP.' });
  }
  challenge.verified = true;
  await challenge.save();
  const user = await User.findOneAndUpdate(
    { mobile },
    { $set: { mobileVerified: true } },
    { new: true, upsert: true },
  );
  res.json({ token: signSession(user), user });
});

authRouter.post('/set-password', async (req, res) => {
  try {
    const payload = jwt.verify(req.body.token, config.jwtSecret);
    const password = String(req.body.password ?? '');
    if (password.length < 8 || !/[^A-Za-z0-9]/.test(password)) {
      return res.status(400).json({ message: 'Password must contain 8 characters and a symbol.' });
    }
    const user = await User.findById(payload.sub).select('+passwordHash');
    if (!user?.mobileVerified) return res.status(401).json({ message: 'Verify mobile first.' });
    user.passwordHash = await bcrypt.hash(password, 12);
    await user.save();
    res.json({ token: signSession(user), user });
  } catch {
    res.status(401).json({ message: 'Invalid or expired verification token.' });
  }
});

authRouter.post('/login', async (req, res) => {
  const mobile = normalizeMobile(req.body.mobile);
  const user = await User.findOne({ mobile }).select('+passwordHash');
  if (!user?.passwordHash || !(await bcrypt.compare(String(req.body.password ?? ''), user.passwordHash))) {
    return res.status(401).json({ message: 'Invalid mobile number or password.' });
  }
  res.json({ token: signSession(user), user });
});
