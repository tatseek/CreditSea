const userCancellableStatuses = new Set(['submitted', 'under_review']);

export const canUserCancelLoan = (status) =>
  userCancellableStatuses.has(status);
