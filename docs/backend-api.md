# CreditSea Backend API

The CreditSea API is an Express service backed by MongoDB. Local development
uses `http://localhost:8080`; Android emulators access the same service through
`http://10.0.2.2:8080`. API routes below are relative to the server origin.

## Configuration

Copy `backend/.env.example` to `backend/.env` and configure:

- `MONGODB_URI`: MongoDB connection URI. The application database is
  `CreditSea` when that database name is present in the URI.
- `JWT_SECRET`: private signing secret for user sessions.
- `ADMIN_API_KEY`: private key accepted only by the status update endpoint.
- `RESEND_API_KEY`: Resend key for real email OTP delivery.
- `EMAIL_FROM`: verified sender, or `CreditSea <onboarding@resend.dev>` while
  using Resend's restricted test mode.
- `CORS_ORIGIN`: allowed frontend origin, or `*` during local development.

Do not commit `.env`. Only `.env.example` belongs in source control.

## Authentication

### Request mobile OTP

`POST /api/auth/request-otp`

```json
{ "mobile": "9999999999" }
```

### Verify mobile OTP

`POST /api/auth/verify-otp`

```json
{ "mobile": "9999999999", "otp": "1234" }
```

The response contains a JWT and user object. Send the JWT on protected routes:

```text
Authorization: Bearer <token>
```

### Create password

`POST /api/auth/set-password`

```json
{ "token": "<verification-token>", "password": "Password@123" }
```

### Sign in

`POST /api/auth/login`

```json
{ "mobile": "9999999999", "password": "Password@123" }
```

## Email verification

Both email endpoints require a Bearer token.

### Send email OTP

`POST /api/email/request-otp`

```json
{ "email": "user@example.com" }
```

The service validates and normalizes the email, replaces any unused challenge,
stores only a bcrypt hash of the generated six-digit OTP, and sends it using
Resend. The challenge expires after `OTP_TTL_MINUTES`.

### Verify email OTP

`POST /api/email/verify-otp`

```json
{ "email": "user@example.com", "otp": "123456" }
```

A successful verification saves the normalized email and sets
`emailVerified` on the authenticated user. Incorrect OTPs return `400`; five
incorrect attempts return `429`.

## Profile

- `GET /api/profile`: return the authenticated user.
- `PATCH /api/profile`: update name, date of birth, gender, marital status,
  PAN, monthly income, and existing monthly EMI.

The profile becomes complete only after required personal details, email
verification, and a valid PAN are present.

## Loans

- `POST /api/loans/eligibility`: evaluate amount and tenure.
- `POST /api/loans`: submit an eligible application.
- `GET /api/loans`: list all applications for the authenticated user.
- `POST /api/loans/:id/accept`: accept an offer and begin review.
- `POST /api/loans/:id/cancel`: cancel a submitted or under-review application.
- `GET /api/loans/:id/status`: return current status and history.
- `PATCH /api/loans/:id/status`: advance status using `x-admin-key`.

Valid status transitions are:

```text
submitted -> under_review -> approved -> disbursed
     |              |
     +-> rejected <-+
     +-> cancelled <-+
```

The calculator accepts amounts from Rs. 10,000 to Rs. 100,000 and terms from
20 to 45 days. Its current calculation uses 1% interest and a 10% processing
fee.

## Health check

`GET /health` returns `{ "status": "ok" }` when the API process is available.
