# CreditSea API

The CreditSea backend is an Express API backed by MongoDB. It handles mobile
authentication, JWT sessions, email verification, profile persistence, loan
eligibility, applications, offers, cancellations, and status tracking.

## Technology

- Node.js 20+
- Express 5
- MongoDB and Mongoose
- JWT authentication
- bcrypt password and OTP hashing
- Resend email delivery
- Vercel serverless functions
- Node's built-in test runner

## Local setup

1. Copy `.env.example` to `.env`.
2. Set `MONGODB_URI` to local MongoDB or MongoDB Atlas.
3. Replace `JWT_SECRET` and `ADMIN_API_KEY` with private random values.
4. Optionally set `RESEND_API_KEY` and `EMAIL_FROM` for real email delivery.
5. Install dependencies and start the API.

```sh
npm install
npm run dev
```

The local server listens on `http://localhost:8080` by default. Android
emulators reach it through `http://10.0.2.2:8080`.

## Environment variables

| Variable | Purpose |
| --- | --- |
| `PORT` | Local HTTP port. Vercel assigns its own port, so do not set this there. |
| `MONGODB_URI` | MongoDB connection string, including the `CreditSea` database name. |
| `JWT_SECRET` | Secret used to sign user session tokens. |
| `JWT_EXPIRES_IN` | JWT lifetime, for example `30d`. |
| `OTP_TTL_MINUTES` | Mobile and email OTP lifetime. |
| `OTP_MODE` | `development` enables staging OTP responses/logging. |
| `STAGING_MOBILE` | Known development mobile number. |
| `STAGING_OTP` | Fixed OTP for the staging mobile number. |
| `CORS_ORIGIN` | Allowed browser origin; the mobile application is not restricted by CORS. |
| `ADMIN_API_KEY` | Secret required to advance an application status. |
| `RESEND_API_KEY` | Resend API credential used for email OTP delivery. |
| `EMAIL_FROM` | Resend sender identity. |

Never commit `.env`; only `.env.example` belongs in source control.

## OTP behavior

### Mobile

The assignment backend intentionally uses a staging OTP instead of an SMS
vendor. With the sample development configuration, mobile `9999999999` uses
OTP `1234`. Real SMS delivery requires integrating a provider and replacing the
development logging branch in `src/routes/auth.js`.

### Email

The backend generates a random six-digit OTP, stores a bcrypt hash in MongoDB,
and sends the original code through Resend. Challenges expire after
`OTP_TTL_MINUTES`; five incorrect attempts are allowed.

The deployed project currently uses Resend's `onboarding@resend.dev` test
sender. Resend test mode permits delivery only to the account owner's verified
recipient, currently `das31arunima@gmail.com`. To support other Gmail addresses,
verify a domain in Resend and change `EMAIL_FROM` to a sender on that domain.

## API groups

- `/api/auth`: mobile OTP registration, password creation, and login
- `/api/email`: authenticated email OTP request and verification
- `/api/profile`: authenticated profile retrieval and updates
- `/api/loans`: eligibility, applications, offers, cancellation, and status
- `/health`: service health check

All routes except mobile authentication and health checks require
`Authorization: Bearer <token>`. Status administration additionally requires
`x-admin-key`.

## Loan rules

- Amount: Rs. 10,000 to Rs. 100,000
- Tenure: 20 to 45 days
- Interest: 1% of principal
- Processing fee: 10% of principal
- Minimum monthly income: Rs. 15,000
- Minimum credit score: 550
- Only one `submitted`, `under_review`, or `approved` application per user
- `submitted` and `under_review` applications can be cancelled by the user

Historical rejected, cancelled, and disbursed applications remain available in
the application's offer and status lists.

## Tests

```sh
npm test
```

The tests cover calculation results, eligibility decisions, cancellation rules,
and terminal application states.

## Vercel deployment

Import the repository and choose `backend` as the Vercel Root Directory. Add
the variables from `.env.example` to the Vercel project, excluding `PORT`.
`api/index.js` is the serverless entry point and caches the Mongoose connection
between warm invocations. `vercel.json` rewrites application paths to that
function.

Current deployment:

- `https://backend-nu-mocha-n1313jnkw2.vercel.app`
- `https://backend-nu-mocha-n1313jnkw2.vercel.app/health`

See [the API contract](../docs/backend-api.md) and
[the architecture guide](../docs/architecture.md) for further details.
