# Sprint 12 SIT Deployment Verification

Date: 2026-07-19

## Scope

Verify the deployed SIT backend signup-start guard and the current PackLox SIT APK readiness for authentication SIT.

Repos checked:

- Backend: `C:\Users\hario\Desktop\projects\collectiq_ai_backend`
- Mobile: `C:\Users\hario\Desktop\projects\collectiq_ai_reconstruction`

## Revisions

- Backend HEAD: `a14f8dc4e3d5879a29971663ffc9b273bcdb0e28`
- Mobile HEAD: `161a1806fd6587d632af746938f74823c4e87ddb`

## Backend Deployment Reachability

### GET /health

Endpoint checked:

```text
GET https://api-sit.packlox.com/health
```

Result: reachable.

- HTTP status: `200 OK`
- Reported environment: `sit`
- Reported status: `healthy`
- Reported Supabase health: configured with service-role credential type, with no secret value exposed in this report

### POST /auth/signup-start - Fresh Email

Endpoint checked:

```text
POST https://api-sit.packlox.com/auth/signup-start
Content-Type: application/json
```

Payload used a unique dummy fresh-format email at `example.invalid`.

Result: reachable and allowed.

```json
{"safeForAccountCreation":true,"delivery":"otpCode","cooldownSeconds":30}
```

Response shape matches the mobile client expectation:

- `safeForAccountCreation`: boolean allow/block flag
- `delivery`: OTP delivery mode string
- `cooldownSeconds`: integer cooldown hint

### POST /auth/signup-start - Confirmed Existing Email

Result: not executed from this machine.

Reason: no safe confirmed SIT account email was provided. The task allowed confirmed-existing testing only if safely available. No personal, production, or guessed account email was used.

## Mobile APK Check

Installed package found:

- Package: `com.collectiq.ai.sit`
- Installed version: `1.0.0` / versionCode `1`
- Previous install/update time: `2026-07-19 21:05:58`
- Latest mobile commit time: `2026-07-19T22:09:12+10:00`

Because the installed APK was older than the latest mobile commit, the SIT APK was rebuilt and installed.

Build command:

```text
build_sit_apk.bat
```

Build result: passed.

Install command:

```text
adb install -r build\app\outputs\flutter-apk\app-sit-debug.apk
```

Install result: `Success`.

Important local config limitation: the build script reported that `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `API_BASE_URL` were not set in the local SIT build environment. For `APP_ENV=sit`, the mobile API base URL still defaults to `https://api-sit.packlox.com`, but real Supabase OTP signup/sign-in/reset flows require the public Supabase URL and anon key to be supplied locally and must not be committed.

## Device-Assisted SIT Flow Results

The refreshed SIT app was launched on the connected Android device with package `com.collectiq.ai.sit`.

Real auth flow verification remains blocked on missing local Supabase public config and no safe test inbox/credentials.

| Flow | Result | Notes |
| --- | --- | --- |
| S02 fresh email proceeds to S03 and sends OTP | Blocked | Backend guard fresh-email allow was verified by API. Real OTP send requires local `SUPABASE_URL` and `SUPABASE_ANON_KEY`. |
| S02 confirmed existing email stays on S02 and does not send OTP | Blocked | No safe confirmed existing SIT account email was provided. |
| S03 OTP field accepts/visualizes 8 digits | Not reverified in live SIT | Requires delivered OTP/test inbox after S02. OTP length was not changed in this sprint. |
| S04 password creation completes only if backend session supports it | Not reverified in live SIT | Requires successful OTP verification and session. |
| S05 real sign-in routes to Home | Blocked | Requires safe confirmed SIT account credentials and Supabase public config. |
| S06 forgot password shows generic confirmation | Blocked | Requires safe test email path and Supabase public config. |

## Required Next Manual SIT Inputs

Before completing the mobile SIT pass, prepare local-only uncommitted SIT config and safe test accounts:

- `config/sit.env` with `SUPABASE_URL`
- `config/sit.env` with `SUPABASE_ANON_KEY`
- optional `API_BASE_URL` only if overriding the built-in SIT backend URL
- safe fresh inbox capable of receiving OTP
- safe confirmed existing SIT account email
- safe confirmed SIT account credentials for S05

No service-role key belongs in Flutter config.

## Retest Sequence

1. Wait until Render shows the backend deploy for `a14f8dc4e3d5879a29971663ffc9b273bcdb0e28` as live.
2. Confirm `GET https://api-sit.packlox.com/health` returns `200 OK`.
3. Confirm `POST https://api-sit.packlox.com/auth/signup-start` returns allow for a fresh email.
4. Create local-only `config/sit.env` with public SIT Supabase values.
5. Rebuild and reinstall the SIT APK with `build_sit_apk.bat` and `adb install -r build\app\outputs\flutter-apk\app-sit-debug.apk`.
6. Test S02 fresh email: expect route to S03 after guard allow and OTP send.
7. Test S02 confirmed existing email: expect S02 to remain visible with the approved safe copy and no OTP send.
8. Test S03 with a delivered 8-digit OTP.
9. Test S04 password creation after OTP verification.
10. Test S05 sign-in with the confirmed SIT account: expect Home.
11. Test S06 forgot password with a safe email: expect generic confirmation.

## Summary

The deployed backend signup-start guard is reachable and returns the expected allow response shape for a fresh email. Full mobile signup SIT could not be honestly completed from this machine because the rebuilt APK did not receive local Supabase public config and no safe confirmed-existing/test-inbox credentials were available.
