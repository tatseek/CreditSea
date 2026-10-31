# Credit Sea Architecture

## Overview

Credit Sea uses a client-server architecture. Flutter owns presentation,
navigation, local session persistence, and API orchestration. Express owns
validation, authentication, eligibility rules, state transitions, and data
persistence. MongoDB is the source of truth; Resend is used only to deliver
email OTP messages.

```text
Android / iOS Flutter app
        |
        | HTTPS + JSON + Bearer JWT
        v
Vercel serverless Express API
        |                    |
        | Mongoose           | Resend SDK
        v                    v
MongoDB Atlas          Recipient mailbox
```

The production Flutter API base URL is compiled into `ApiClient` and can be
replaced using `--dart-define=API_BASE_URL=...` for local or staging builds.

## Flutter application

### Application shell

- `lib/main.dart` initializes Flutter and shared services.
- `lib/app/app.dart` defines the Material application and initial navigation.
- `lib/core/bootstrap/app_services.dart` registers the permanent
  `SessionService` using GetX dependency injection.

### Core layer

`ApiClient` provides JSON `GET`, `POST`, and `PATCH` requests, a 15-second
timeout, error normalization, and automatic Bearer-token headers.

`SessionService` is the client-side session authority. It:

- stores the JWT using `flutter_secure_storage`;
- restores the token during startup;
- fetches `/profile` to validate a restored session;
- exposes the current user as reactive state; and
- clears invalid or expired sessions.

No MongoDB credentials, Resend credentials, admin key, or backend `.env` values
are bundled into the APK.

### Feature layer

Each business area groups presentation and data access:

```text
features/auth/
  data/auth_repository.dart
  presentation/auth_controller.dart
  presentation/auth_screen.dart

features/details/
  data/profile_repository.dart
  presentation/details_flow_screen.dart

features/loan/
  data/loan_repository.dart
  presentation/loan_flow_screens.dart
  presentation/loan_collection_screens.dart
```

Repositories translate UI actions into API calls. Screens/controllers own form
state, validation feedback, transitions, and rendering. The home and splash
features select the correct entry point from restored session/profile state.

## Express backend

### Entry points

- `src/server.js` starts the long-running local development server.
- `api/index.js` exports a Vercel handler and reuses a cached MongoDB connection.
- `src/app.js` configures Helmet, CORS, JSON limits, rate limiting, routes,
  health checks, and the shared error handler.

### Request pipeline

```text
Request
  -> Vercel rewrite
  -> MongoDB connection
  -> Helmet / CORS / JSON middleware
  -> API rate limiter
  -> JWT authentication for protected routes
  -> Route validation and service rules
  -> Mongoose model
  -> JSON response
```

`requireAuth` verifies the JWT, reads its user ID from `sub`, loads the user,
and attaches it to the request. The API never trusts a user ID supplied by the
client for protected resources.

### Routes and services

- `routes/auth.js`: mobile normalization, OTP challenges, password hashing,
  login, and JWT issuance.
- `routes/emailVerification.js`: email normalization, OTP challenges, Resend
  delivery, attempt limits, and verified-email persistence.
- `routes/profile.js`: whitelisted profile updates, PAN-format verification,
  and profile-completion calculation.
- `routes/loans.js`: eligibility checks, application creation, listing,
  acceptance, cancellation, and guarded status transitions.
- `services/eligibility.js`: pure calculation and eligibility rules.
- `services/loanStatus.js`: user cancellation policy.
- `services/email.js`: Resend adapter and development fallback.

## MongoDB data model

### User

Stores the normalized mobile number, hashed password, verification flags,
personal profile, income/EMI inputs, credit score, PAN, and completion state.
Password hashes are excluded from normal queries.

### OTP challenges

`OtpChallenge` and `EmailOtpChallenge` hold bcrypt hashes rather than plaintext
codes. A challenge tracks expiry, verification state, and failed attempts. A
new request invalidates the previous unused challenge for that mobile/user.

### Loan application

Each loan stores its owner, amount, tenure, purpose, rate snapshot, calculated
fees, total payable, eligibility result, current status, and chronological
status history. Keeping the calculation snapshot makes historical applications
stable even if rules change later.

## Authentication and onboarding sequence

```text
Request mobile OTP
  -> Verify mobile OTP
  -> Receive JWT
  -> Create password
  -> Save personal details
  -> Request and verify email OTP
  -> Save PAN
  -> profileCompleted = true
```

Returning users log in with mobile number and password. The Flutter client
stores only the JWT; the API reloads authoritative user data from MongoDB.

## Loan lifecycle

```text
submitted -> under_review -> approved -> disbursed
     |              |
     +-> rejected <-+
     +-> cancelled <-+
```

Offer acceptance moves `submitted` to `under_review`. Users can cancel only
`submitted` or `under_review` applications. The admin status endpoint permits
only predefined forward transitions and requires `x-admin-key`. Terminal
applications remain queryable so multiple historical loans can be displayed.

## Eligibility calculation

The API, not the Flutter sliders, is authoritative. It evaluates profile
completion, income, credit score, requested amount, tenure, and existing EMI.
The maximum amount is capped at Rs. 100,000 and derived from income, credit
score, and existing EMI. The current repayment breakdown adds 1% interest and
a 10% processing fee to principal.

## Security boundaries

- Secrets remain in local/Vercel environment variables, never in Flutter.
- Passwords and OTPs are bcrypt-hashed.
- Protected resources are scoped using the authenticated user ID.
- Loan status administration requires a separate server-side key.
- API requests are rate-limited and JSON bodies are size-limited.
- HTTPS is provided by Vercel for production traffic.

This remains an assignment/demo architecture: mobile OTP delivery uses a
staging flow, PAN verification checks format rather than a government service,
and the admin status endpoint is an API rather than a complete operations UI.

## Deployment topology

The Flutter release APK calls the Vercel API over HTTPS. Vercel runs the Express
handler as a serverless function and connects to MongoDB Atlas. The function
reuses an existing Mongoose connection when its runtime stays warm. Vercel
assigns its own runtime port, so local `PORT=8080` is not configured in Vercel.

