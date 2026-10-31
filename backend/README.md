# CreditSea API

Node.js and MongoDB API for OTP authentication, profile persistence, loan
eligibility, applications, and application status tracking.

## Local setup

1. Copy `.env.example` to `.env` and change `JWT_SECRET` and `ADMIN_API_KEY`.
2. Start MongoDB locally or set `MONGODB_URI` to MongoDB Atlas.
3. Add `RESEND_API_KEY` to deliver real email OTPs. Set `EMAIL_FROM` to a
   verified sender when sending beyond Resend's test recipient.
4. Run `npm install` and `npm run dev`.

The Android emulator reaches the host API at `http://10.0.2.2:8080`.
Development mode returns/logs the mobile OTP; the configured staging
credentials are mobile `9999999999` and OTP `1234`. Production must replace the
mobile logging branch with an SMS provider and set `OTP_MODE=production`.

Email OTPs are six digits, hashed in MongoDB, expire according to
`OTP_TTL_MINUTES`, and allow at most five incorrect verification attempts.
When `RESEND_API_KEY` is configured, they are delivered through Resend.

## API

- `POST /api/auth/request-otp`
- `POST /api/auth/verify-otp`
- `POST /api/auth/set-password`
- `POST /api/auth/login`
- `POST /api/email/request-otp`
- `POST /api/email/verify-otp`
- `GET|PATCH /api/profile`
- `POST /api/loans/eligibility`
- `POST|GET /api/loans`
- `POST /api/loans/:id/accept`
- `GET /api/loans/:id/status`
- `PATCH /api/loans/:id/status` with `x-admin-key` to advance an application

Allowed status transitions are `submitted -> under_review -> approved ->
disbursed`, with rejection possible from submitted or under review.

Every endpoint except mobile authentication and `/health` requires an
`Authorization: Bearer <token>` header. Never commit `.env`; use
`.env.example` as the configuration template.

For request and response details, see `../docs/backend-api.md`.
