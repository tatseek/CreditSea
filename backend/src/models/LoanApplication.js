import mongoose from 'mongoose';

const statusEntrySchema = new mongoose.Schema(
  {
    status: {
      type: String,
      enum: ['submitted', 'under_review', 'approved', 'rejected', 'disbursed'],
      required: true,
    },
    note: String,
    changedAt: { type: Date, default: Date.now },
  },
  { _id: false },
);

const loanApplicationSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true, min: 1000 },
    tenureDays: { type: Number, required: true, min: 20, max: 45 },
    purpose: { type: String, required: true, trim: true },
    dailyInterestRate: { type: Number, required: true },
    processingFeeRate: { type: Number, required: true },
    interestAmount: { type: Number, required: true },
    processingFee: { type: Number, required: true },
    totalPayable: { type: Number, required: true },
    eligibility: {
      eligible: Boolean,
      maximumEligibleAmount: Number,
      reasons: [String],
    },
    status: {
      type: String,
      enum: ['submitted', 'under_review', 'approved', 'rejected', 'disbursed'],
      default: 'submitted',
      index: true,
    },
    statusHistory: [statusEntrySchema],
  },
  { timestamps: true },
);

export const LoanApplication = mongoose.model(
  'LoanApplication',
  loanApplicationSchema,
);
