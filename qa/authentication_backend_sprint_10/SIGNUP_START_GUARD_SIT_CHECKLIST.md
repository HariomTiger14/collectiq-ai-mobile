# Signup Start Guard SIT Checklist

## Deployment Gate

- The backend endpoint `POST /auth/signup-start` must be deployed before SIT can verify real Create Account behavior.
- Flutter SIT builds must point `API_BASE_URL` at the backend deployment that includes the Sprint 10 endpoint.

## Required SIT Config Names

Do not print or share secret values.

- Backend:
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
- Flutter:
  - `APP_ENV`
  - `API_BASE_URL`
  - `SUPABASE_ENABLED`
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `USE_CLOUD_AUTH` or `COLLECTIQ_USE_CLOUD_AUTH`

## Manual Test Cases

1. Fresh email should proceed S02 -> S03 after OTP send.
   - Use an email with no confirmed Supabase Auth user.
   - Tap Create Account continue on S02.
   - Expected: S03 Verify Email appears only after signup-start guard allow and Supabase OTP send.

2. Confirmed existing email should stay on S02 and not send OTP.
   - Use an email for a confirmed existing Supabase Auth user.
   - Tap Create Account continue on S02.
   - Expected: S02 stays visible with:
     - `We couldn't start account creation for this email. Try signing in or resetting your password.`
   - Expected: no S03 route, no Create Account OTP email/code, no authenticated session, no password overwrite.

3. Unconfirmed existing email should be allowed to continue/resend OTP.
   - Use an email with a Supabase Auth user whose confirmation fields are unset.
   - Tap Create Account continue on S02.
   - Expected: S03 appears after OTP send.
   - Expected: resend OTP remains available through the existing S03 resend behavior.

4. Backend/API failure should stay on S02 with safe retry copy.
   - Point `API_BASE_URL` to an unavailable backend, or temporarily deploy backend without `POST /auth/signup-start`.
   - Tap Create Account continue on S02.
   - Expected: S02 stays visible with retryable safe copy.
   - Expected: no S03 route and no Supabase OTP request.

5. S05 real sign-in should route to Home.
   - Use a confirmed account and valid password.
   - Submit S05 Sign In.
   - Expected: authenticated state wins and app routes to Home.

6. S06 forgot password should show generic confirmation.
   - Request reset for a known email and an unknown email.
   - Expected: both show the generic confirmation copy without account existence disclosure.
