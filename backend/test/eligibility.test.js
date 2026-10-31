import test from 'node:test';
import assert from 'node:assert/strict';
import { calculateLoanBreakdown, evaluateEligibility } from '../src/services/eligibility.js';

test('matches the calculator interest, fee and total', () => {
  assert.deepEqual(calculateLoanBreakdown(55000), {
    dailyInterestRate: 1,
    processingFeeRate: 10,
    interestAmount: 550,
    processingFee: 5500,
    totalPayable: 61050,
  });
});

test('approves an affordable day-based application', () => {
  const result = evaluateEligibility(
    { profileCompleted: true, monthlyIncome: 50000, existingMonthlyEmi: 0, creditScore: 650 },
    55000,
    36,
  );
  assert.equal(result.eligible, true);
  assert.equal(result.maximumEligibleAmount, 100000);
  assert.equal(result.totalPayable, 61050);
});

test('rejects incomplete or unaffordable applications with reasons', () => {
  const result = evaluateEligibility(
    { profileCompleted: false, monthlyIncome: 10000, existingMonthlyEmi: 8000, creditScore: 500 },
    50000,
    36,
  );
  assert.equal(result.eligible, false);
  assert.ok(result.reasons.length >= 3);
});
