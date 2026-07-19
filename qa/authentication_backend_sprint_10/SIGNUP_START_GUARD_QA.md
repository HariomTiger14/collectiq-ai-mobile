# Authentication Backend Sprint 10 - Signup Start Guard QA

## Guard Location

- Chosen path: CollectIQ FastAPI backend endpoint, `POST /auth/signup-start`.
- Rationale: the repo already has a trusted backend with server-side Supabase environment variables, including `SUPABASE_SERVICE_ROLE_KEY`. No admin credential is added to Flutter.
- Supabase Edge Functions were not selected because this repo has Supabase migrations/setup only, while the FastAPI backend is already wired into SIT via `API_BASE_URL`.

## Contract

- Fresh/new email:
  - Backend uses the Supabase Admin API with the service-role key server-side.
  - If no matching auth user exists, backend returns `safeForAccountCreation: true`.
  - Flutter then sends the existing Supabase OTP signup request and routes S02 to S03 only after both steps succeed.
- Existing email:
  - Backend returns `safeForAccountCreation: false`.
  - Flutter does not request Supabase OTP.
  - S02 stays on-screen with:
    - `We couldn't start account creation for this email. Try signing in or resetting your password.`
- Backend/config/network failure:
  - Backend returns a retryable failure for unavailable admin lookup.
  - Flutter maps network/config failure to retryable safe copy and does not route to S03.

## Security Notes

- Flutter receives only the public backend result and continues to use the public Supabase anon key for OTP.
- `SUPABASE_SERVICE_ROLE_KEY` remains backend-only.
- The mobile app has no service-role/admin credential.
- The backend response does not include user IDs, registered/exists wording, tokens, or secrets.
- Rate limiting: `POST /auth/signup-start` uses an in-memory per-client/email throttle of 5 attempts per 5 minutes. This should be replaced or backed by shared storage if multiple backend instances are deployed.

## Validation Checklist

- Fresh email S02 -> S03 OTP path.
- Existing registered email remains on S02.
- Existing email cannot proceed through Create Account to OTP/password creation.
- Backend/config/network failure remains on S02 with retryable copy.
- S05/S06 sign-in and forgot-password behavior unchanged.

## SIT Status

- Real SIT device verification was not performed in this code pass.
- Required SIT env:
  - Backend: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.
  - Flutter: `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_ENABLED=true`, `USE_CLOUD_AUTH=true`.
