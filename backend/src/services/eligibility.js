const DAILY_INTEREST_RATE = 0.01;
const PROCESSING_FEE_RATE = 0.10;

export function calculateLoanBreakdown(amount) {
  const interestAmount = Math.round(amount * DAILY_INTEREST_RATE);
  const processingFee = Math.round(amount * PROCESSING_FEE_RATE);
  return {
    dailyInterestRate: DAILY_INTEREST_RATE * 100,
    processingFeeRate: PROCESSING_FEE_RATE * 100,
    interestAmount,
    processingFee,
    totalPayable: Math.round(amount + interestAmount + processingFee),
  };
}

export function evaluateEligibility(user, requestedAmount, tenureDays) {
  const monthlyIncome = Number(user.monthlyIncome ?? 0);
  const existingEmi = Number(user.existingMonthlyEmi ?? 0);
  const creditScore = Number(user.creditScore ?? 650);
  const incomeMultiplier = creditScore >= 750 ? 2.5 : creditScore >= 650 ? 2 : 1.5;
  const maximumEligibleAmount = Math.max(
    0,
    Math.min(100000, Math.floor(monthlyIncome * incomeMultiplier - existingEmi * 3)),
  );
  const reasons = [];
  if (!user.profileCompleted) reasons.push('Complete your profile before applying.');
  if (monthlyIncome < 15000) reasons.push('Minimum monthly income is ₹15,000.');
  if (creditScore < 550) reasons.push('Credit score must be at least 550.');
  if (requestedAmount > maximumEligibleAmount) {
    reasons.push(`Maximum eligible amount is ₹${maximumEligibleAmount}.`);
  }
  if (tenureDays < 20 || tenureDays > 45) {
    reasons.push('Loan tenure must be between 20 and 45 days.');
  }
  return {
    eligible: reasons.length === 0,
    maximumEligibleAmount,
    tenureDays,
    creditScore,
    ...calculateLoanBreakdown(requestedAmount),
    reasons,
  };
}
