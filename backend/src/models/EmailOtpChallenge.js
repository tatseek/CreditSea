import mongoose from 'mongoose';

const emailOtpChallengeSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    email: { type: String, required: true, lowercase: true, trim: true },
    otpHash: { type: String, required: true },
    attempts: { type: Number, default: 0 },
    verified: { type: Boolean, default: false },
    expiresAt: { type: Date, required: true, expires: 0 },
  },
  { timestamps: true },
);

export const EmailOtpChallenge = mongoose.model(
  'EmailOtpChallenge',
  emailOtpChallengeSchema,
);
