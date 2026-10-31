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

Start the API separately, then run the Flutter application:

```sh
flutter pub get
flutter run
```

The Android emulator uses `http://10.0.2.2:8080/api` by default. Override the
API endpoint for another environment with:

```sh
flutter run --dart-define=API_BASE_URL=https://example.com/api
```

The backend is intentionally excluded from this frontend repository.
