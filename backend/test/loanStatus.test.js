import test from 'node:test';
import assert from 'node:assert/strict';
import { canUserCancelLoan } from '../src/services/loanStatus.js';

test('allows users to cancel submitted and under-review applications', () => {
  assert.equal(canUserCancelLoan('submitted'), true);
  assert.equal(canUserCancelLoan('under_review'), true);
});

test('does not cancel completed or terminal applications', () => {
  for (const status of ['approved', 'rejected', 'cancelled', 'disbursed']) {
    assert.equal(canUserCancelLoan(status), false);
  }
});
