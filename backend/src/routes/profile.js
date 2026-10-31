import express from 'express';
import { requireAuth } from '../middleware/auth.js';

export const profileRouter = express.Router();
profileRouter.use(requireAuth);

profileRouter.get('/', (req, res) => res.json({ user: req.user }));

profileRouter.patch('/', async (req, res) => {
  const allowed = [
    'firstName', 'lastName', 'dateOfBirth', 'gender', 'maritalStatus',
    'pan', 'monthlyIncome', 'existingMonthlyEmi',
  ];
  for (const key of allowed) {
    if (req.body[key] !== undefined) req.user[key] = req.body[key];
  }
  if (req.user.pan) req.user.panVerified = /^[A-Z]{5}[0-9]{4}[A-Z]$/.test(req.user.pan);
  req.user.profileCompleted = Boolean(
    req.user.firstName && req.user.lastName && req.user.dateOfBirth &&
    req.user.gender && req.user.emailVerified && req.user.panVerified,
  );
  await req.user.save();
  res.json({ user: req.user });
});
