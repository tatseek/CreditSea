import mongoose from 'mongoose';

const otpChallengeSchema = new mongoose.Schema(
  {
    mobile: { type: String, required: true, index: true },
    otpHash: { type: String, required: true },
    attempts: { type: Number, default: 0 },
    verified: { type: Boolean, default: false },
    expiresAt: { type: Date, required: true, expires: 0 },
  },
  { timestamps: true },
);

export const OtpChallenge = mongoose.model('OtpChallenge', otpChallengeSchema);
