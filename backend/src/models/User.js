import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    mobile: { type: String, required: true, unique: true, index: true },
    passwordHash: { type: String, default: null, select: false },
    mobileVerified: { type: Boolean, default: false },
    firstName: { type: String, trim: true },
    lastName: { type: String, trim: true },
    dateOfBirth: Date,
    gender: { type: String, enum: ['male', 'female', 'other'] },
    maritalStatus: { type: String, enum: ['single', 'married', 'other'] },
    email: { type: String, lowercase: true, trim: true },
    emailVerified: { type: Boolean, default: false },
    pan: { type: String, uppercase: true, trim: true },
    panVerified: { type: Boolean, default: false },
    monthlyIncome: { type: Number, min: 0 },
    existingMonthlyEmi: { type: Number, min: 0, default: 0 },
    creditScore: { type: Number, min: 300, max: 900, default: 650 },
    profileCompleted: { type: Boolean, default: false },
  },
  { timestamps: true },
);

export const User = mongoose.model('User', userSchema);
