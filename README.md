# Credit Sea

Flutter frontend for the CreditSea loan application assignment.

## Current flow

Splash → Register or Sign in → Personal details → Email verification → PAN
verification → Home → Loan calculator → Offer → Application status.

Returning users with a completed profile open the home screen directly. The
home screen provides entry points for applying for a loan, reviewing the latest
offer, and tracking application status.

## Development credentials

- Mobile number: `9999999999`
- Mobile OTP: `1234`
- Email OTP: `123456`

## Run

Install and start the API:

```sh
cd backend
cp .env.example .env
npm install
npm run dev
```

Then run the Flutter application from the repository root:

```sh
flutter pub get
flutter run
```

The Android emulator uses `http://10.0.2.2:8080/api` by default. Override the
API endpoint for another environment with:

```sh
flutter run --dart-define=API_BASE_URL=https://example.com/api
```

## Backend

The Node.js and MongoDB backend is included in [`backend`](backend). It provides
JWT authentication, mobile and email OTP verification, profile persistence,
loan eligibility, multiple loan applications, offers, and status tracking.

See [`backend/README.md`](backend/README.md) for configuration and
[`docs/backend-api.md`](docs/backend-api.md) for the API contract.
