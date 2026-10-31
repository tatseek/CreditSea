import express from 'express';
import { config } from '../config.js';
import { requireAuth } from '../middleware/auth.js';
import { LoanApplication } from '../models/LoanApplication.js';
import { evaluateEligibility } from '../services/eligibility.js';

export const loanRouter = express.Router();
loanRouter.use(requireAuth);

const parseRequest = (body) => ({
  amount: Number(body.amount),
  tenureDays: Number(body.tenureDays),
  purpose: String(body.purpose ?? '').trim(),
});

loanRouter.post('/eligibility', (req, res) => {
  const input = parseRequest(req.body);
  if (input.amount < 10000 || input.amount > 100000 || input.tenureDays < 20 || input.tenureDays > 45) {
    return res.status(400).json({ message: 'Invalid loan amount or tenure.' });
  }
  res.json(evaluateEligibility(req.user, input.amount, input.tenureDays));
});

loanRouter.post('/', async (req, res) => {
  const input = parseRequest(req.body);
  if (!input.purpose) return res.status(400).json({ message: 'Loan purpose is required.' });
  const activeLoan = await LoanApplication.findOne({
    user: req.user.id,
    status: { $in: ['submitted', 'under_review', 'approved'] },
  }).sort({ createdAt: -1 });
  if (activeLoan) {
    return res.status(409).json({
      message: 'You already have an active loan application.',
      activeLoanId: activeLoan.id,
      status: activeLoan.status,
    });
  }
  const eligibility = evaluateEligibility(req.user, input.amount, input.tenureDays);
  if (!eligibility.eligible) return res.status(422).json({ message: 'Loan is not eligible.', eligibility });
  const loan = await LoanApplication.create({
    user: req.user.id,
    ...input,
    dailyInterestRate: eligibility.dailyInterestRate,
    processingFeeRate: eligibility.processingFeeRate,
    interestAmount: eligibility.interestAmount,
    processingFee: eligibility.processingFee,
    totalPayable: eligibility.totalPayable,
    eligibility,
    statusHistory: [{ status: 'submitted', note: 'Application received.' }],
  });
  res.status(201).json({ loan });
});

loanRouter.get('/', async (req, res) => {
  const loans = await LoanApplication.find({ user: req.user.id }).sort({ createdAt: -1 });
  res.json({ loans });
});

loanRouter.post('/:id/accept', async (req, res) => {
  const loan = await LoanApplication.findOne({ _id: req.params.id, user: req.user.id });
  if (!loan) return res.status(404).json({ message: 'Loan application not found.' });
  if (loan.status === 'submitted') {
    loan.status = 'under_review';
    loan.statusHistory.push({
      status: 'under_review',
      note: 'Offer accepted and application sent for review.',
    });
    await loan.save();
  }
  res.json({ loan });
});

loanRouter.patch('/:id/status', async (req, res) => {
  if (req.headers['x-admin-key'] !== config.adminApiKey) {
    return res.status(403).json({ message: 'Admin access required.' });
  }
  const nextStatus = String(req.body.status ?? '');
  const transitions = {
    submitted: ['under_review', 'rejected'],
    under_review: ['approved', 'rejected'],
    approved: ['disbursed'],
    rejected: [],
    disbursed: [],
  };
  const loan = await LoanApplication.findById(req.params.id);
  if (!loan) return res.status(404).json({ message: 'Loan application not found.' });
  if (!transitions[loan.status]?.includes(nextStatus)) {
    return res.status(409).json({
      message: `Cannot move application from ${loan.status} to ${nextStatus}.`,
    });
  }
  loan.status = nextStatus;
  loan.statusHistory.push({
    status: nextStatus,
    note: String(req.body.note ?? `Application moved to ${nextStatus}.`),
  });
  await loan.save();
  res.json({ loan });
});

loanRouter.get('/:id/status', async (req, res) => {
  const loan = await LoanApplication.findOne({ _id: req.params.id, user: req.user.id });
  if (!loan) return res.status(404).json({ message: 'Loan application not found.' });
  res.json({ id: loan.id, status: loan.status, history: loan.statusHistory });
});
