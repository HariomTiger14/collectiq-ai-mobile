# Authentication Backend Sprint 07 - SIT Auth Runtime Verification

Date: 2026-07-19
Branch: `rebuild/product-language-v1`
HEAD inspected: `5406b27eeb541b38f236a89650991db63de9e056`

## Scope

Verify the wired Authentication S01-S06 flow against real SIT Supabase on a Samsung device without changing product behavior.

## Result

Status: Blocked before APK build/install.

Reason: required local SIT Supabase configuration and safe test-account access are not available on this machine.

## Repository And Config Inspection

Working tree before QA documentation: clean.

Expected runtime config path:

- `config/sit.env`

Available committed examples/docs/scripts:

- `config/sit.env.example`
- `docs/SIT_BUILD_SETUP.md`
- `docs/SIT_REAL_APP_SETUP.md`
- `docs/SUPABASE_LIVE_SIT_SETUP.md`
- `docs/PACKLOX_REAL_DEVICE_SIT_COMMANDS.md`
- `run_sit.bat`
- `build_sit_apk.bat`
- `check_supabase_sit.bat`
- `test_sit_deeplink.bat`

Supabase config is read by `SupabaseConfig.fromEnvironment()` using compile-time dart defines:

- `SUPABASE_ENABLED`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

The SIT scripts load `config/sit.env` and pass:

- `--dart-define=APP_ENV=sit`
- `--dart-define=USE_CLOUD_AUTH=true`
- `--dart-define=USE_CLOUD_PORTFOLIO_SYNC=true`
- `--dart-define=USE_CLOUD_IMAGE_STORAGE=true`
- `--dart-define=SUPABASE_ENABLED=true`
- `--dart-define=SUPABASE_URL=...`
- `--dart-define=SUPABASE_ANON_KEY=...`

No Supabase anon key value was printed or copied into this report.

## Local Availability Check

Missing local files:

- `config/sit.env`
- `.env`
- `.env.sit`
- `backend/.env`
- `backend/.env.sit`

Missing process environment:

- `SUPABASE_ENABLED`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SIT_TEST_EMAIL`
- `SIT_TEST_PASSWORD`

Safe test inbox / OTP access: not available in this environment.

## Required Inputs To Resume Runtime Verification

Provide the following locally, without committing them:

```text
SUPABASE_ENABLED=true
SUPABASE_URL=<SIT Supabase project URL>
SUPABASE_ANON_KEY=<SIT public anon key>
safe test email/inbox/OTP access
safe existing test account email/password for S05 sign-in
safe new test email/inbox for S02-S04 signup
```

The expected local file is `config/sit.env`, copied from `config/sit.env.example`.

## APK / Device Result

SIT APK built: No.

Samsung SM-E625F install/run: Not attempted.

Reason: building/installing without `SUPABASE_URL` and `SUPABASE_ANON_KEY` would produce a SIT app with Supabase disabled or missing-config behavior, which would not verify the requested real Supabase runtime auth flow.

## Verification Checklist Status

1. Fresh unauthenticated launch opens S01: Not run, blocked by missing SIT config.
2. S05 real sign-in with safe existing test account: Not run, blocked by missing SIT config and test credentials.
3. Relaunch restores authenticated session: Not run.
4. Guest mode does not override signed-in session: Covered by fake-backed tests; real SIT not run.
5. S06 real reset request: Not run, blocked by missing SIT config and safe test inbox.
6. S02-S04 real signup: Not run, blocked by missing SIT config and safe OTP inbox access.
7. OTP verification produces usable session for S04 password creation: Not verified. This remains the main SIT risk from Sprint 06.

## Screenshots And Logs

No device screenshots were captured.

No `adb logcat` snippets were captured.

Reason: runtime device verification was intentionally stopped before APK build/install because required SIT config and safe test credentials were missing.

## Validation Results

- `flutter analyze`: Passed, no issues found.
- `flutter test test/auth_backend_contract_test.dart`: Passed, 13 tests.
- `flutter test test/auth_presentation_test.dart`: Passed, 49 tests.

Validation note: test output confirms Supabase is disabled in the local test environment:

- Supabase enabled: false
- Supabase URL configured: false
- Supabase anon key configured: false
- Supabase anon key length: 0

## Remaining Blockers

- `config/sit.env` must be created locally with SIT public Supabase config.
- Safe existing SIT user credentials are required for S05 sign-in verification.
- Safe new test email/inbox/OTP access is required for S02-S04 signup verification.
- Real Supabase OTP delivery and `verifyOTP` behavior must be checked.
- S04 password creation must be verified only after Supabase OTP verification returns a usable session; do not fake auth success if the session is missing.

## Next Action

After the missing SIT config and safe test inbox are supplied, run:

```bat
.\check_supabase_sit.bat
.\build_sit_apk.bat
adb install -r build\app\outputs\flutter-apk\app-sit-debug.apk
```

Then manually verify S01-S06 on the Samsung SM-E625F with screenshots and sanitized logs.
