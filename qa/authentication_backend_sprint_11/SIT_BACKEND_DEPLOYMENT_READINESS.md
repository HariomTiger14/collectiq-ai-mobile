# Authentication Backend Sprint 11 - SIT Backend Deployment Readiness

## Summary

- Endpoint under review: `POST /auth/signup-start`
- Local repo status at review time: clean before this report was created.
- Code changes made in Sprint 11: none.
- Secret values printed or recorded: none.

## Endpoint Readiness

- Route exists in `backend/app/routers/auth.py`.
- Method/path is `POST /auth/signup-start`.
- Request body accepts an `email` field.
- Successful response shape includes:
  - `safeForAccountCreation`
  - `delivery`
  - `cooldownSeconds`
- Failure behavior:
  - Invalid email returns HTTP `422`.
  - Local rate limit returns HTTP `429`.
  - Missing backend/Supabase admin config or upstream lookup failure returns HTTP `503`.
- The endpoint requires backend deployment before Flutter SIT Create Account can pass real signup-start verification.

## Router Registration Status

- `backend/app/main.py` imports `auth` from `app.routers`.
- `backend/app/main.py` registers `app.include_router(auth.router)`.
- FastAPI registration status: ready in source.

## Required Environment Names

Values must remain in local/deployment secrets and must not be committed.

Backend:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

Flutter SIT:

- `APP_ENV`
- `API_BASE_URL`
- `SUPABASE_ENABLED`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `USE_CLOUD_AUTH` or `COLLECTIQ_USE_CLOUD_AUTH`

## Deployment Mechanism Found

Found:

- `backend/Dockerfile`
- `backend/requirements.txt`
- `backend/run_backend_local.bat`
- `backend/run_backend_sit_mock.bat`
- `backend/run_backend_sit_openai.bat`
- `scripts/run_backend_tests.ps1`
- `scripts/run_backend_quality.ps1`
- `docs/BACKEND_SIT_DEPLOYMENT.md`
- `backend/README.md`

No provider-specific committed hosting config was found for:

- Render blueprint file
- Railway config
- Fly.io config
- Vercel config
- Procfile
- GitHub Actions workflow directory

Deployment docs identify Render as the recommended SIT target. The documented Uvicorn target is:

```text
app.main:app
```

The documented start command is:

```text
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

## Local Run Result

Backend runnable locally on this machine: no.

Exact blockers:

- `python` is not on PATH.
- `py` is not available; `py -m unittest discover tests` returns `No installed Python found!`.
- `uvicorn` is not on PATH.
- `docker` is not on PATH.
- No project virtualenv was found from `python.exe`, `pyvenv.cfg`, or activation-file search.

Because no Python/backend runner is available, the backend could not be started locally and backend unit tests could not be executed on this machine.

## Remote SIT Probe Result

Documented SIT backend origin checked:

```text
https://api-sit.packlox.com
```

Commands used without secrets:

```text
curl.exe -i -sS --max-time 15 https://api-sit.packlox.com/health
curl.exe -i -sS --max-time 15 -X POST https://api-sit.packlox.com/auth/signup-start -H "Content-Type: application/json" -d '{"email":"sprint11-dummy@example.invalid"}'
```

Result:

- `GET /health`: timed out after 15 seconds with 0 bytes received.
- `POST /auth/signup-start`: timed out after 15 seconds with 0 bytes received.

Endpoint reachable from this machine at review time: no.

## SIT Deployment Checklist

1. Deploy the backend commit that includes Sprint 10 auth router files.
2. Use the backend root as the service root if required by the host.
3. Install `backend/requirements.txt`.
4. Start with Uvicorn target `app.main:app`.
5. Use host-provided `$PORT`.
6. Configure backend environment names:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `SUPABASE_ANON_KEY` if health checks or other backend flows need it
   - `SUPABASE_HEALTH_REQUIRED`
   - `ENVIRONMENT` or `BACKEND_ENV`
   - `AI_PROVIDER`
   - `PRICING_PROVIDER`
   - `CORS_ALLOWED_ORIGINS`
7. Do not print or commit secret values.
8. Verify deployment health:
   - `GET {API_BASE_URL}/health`
   - `GET {API_BASE_URL}/version`
9. Verify signup-start endpoint with a dummy email:
   - `POST {API_BASE_URL}/auth/signup-start`
10. Update Flutter SIT config so `API_BASE_URL` is the backend origin only, with no route suffix.

## APK/SIT Retest Sequence After Deployment

1. Build/install a SIT APK with:
   - `APP_ENV=sit`
   - `API_BASE_URL=<deployed backend origin>`
   - `SUPABASE_ENABLED=true`
   - `SUPABASE_URL=<SIT Supabase project URL>`
   - `SUPABASE_ANON_KEY=<public anon key>`
   - `USE_CLOUD_AUTH=true` or `COLLECTIQ_USE_CLOUD_AUTH=true`
2. Confirm app launches signed out or in the expected auth state.
3. Fresh email:
   - Open S02 Create Account.
   - Enter an email with no confirmed Supabase Auth user.
   - Continue.
   - Expected: S03 appears after OTP send.
4. Confirmed existing email:
   - Enter an email for a confirmed Supabase Auth user.
   - Continue.
   - Expected: S02 remains visible with the safe Create Account copy.
   - Expected: no S03 route and no Create Account OTP.
5. Unconfirmed existing email:
   - Enter an email with an unconfirmed Supabase Auth user.
   - Continue.
   - Expected: S03 appears and resend OTP remains available.
6. Backend/API failure:
   - Temporarily point `API_BASE_URL` to an unavailable backend or block the endpoint.
   - Continue from S02.
   - Expected: S02 remains visible with retryable safe copy.
7. S05 real sign-in:
   - Use a confirmed test account and valid password.
   - Expected: route to Home.
8. S06 forgot password:
   - Request reset for known and unknown emails.
   - Expected: generic confirmation in both cases.

## Readiness Decision

- Source readiness: ready.
- Local runtime readiness on this machine: blocked by missing Python/backend runner.
- Remote SIT endpoint readiness: not reachable at `https://api-sit.packlox.com` during this review.
- SIT cannot complete real Create Account verification until the backend endpoint is deployed and reachable from the app's configured `API_BASE_URL`.
