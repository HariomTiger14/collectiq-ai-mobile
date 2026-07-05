# PackLox Real-Device SIT Results

Date: 2026-07-05

Device:

- Android device id: `RZ8R213M8ZL`
- Model: `SM-E625F`
- Phone LAN IP observed: `192.168.0.164`

Mock Analyzer API:

- Command: `py -m uvicorn app.main:app --host 0.0.0.0 --port 8000`
- Health endpoint: `http://192.168.0.81:8000/health`
- Health response confirmed mock providers: `ai_provider=mock`, `pricing_provider=mock`

App run command:

```powershell
.\run_sit.bat -d RZ8R213M8ZL
```

Required SIT values confirmed:

- `APP_ENV=sit`
- `SUPABASE_URL` configured for SIT Supabase project
- `SUPABASE_ANON_KEY` configured; value redacted, observed length `208`
- `API_BASE_URL=http://192.168.0.81:8000`

Do not expose or commit the Supabase anon key value in logs, docs, screenshots,
or issue reports.

## Checklist

| Flow | Status | Evidence |
| --- | --- | --- |
| Device detected | PASS | `adb devices` showed `RZ8R213M8ZL device`. |
| Same-LAN API reachability | PASS | Device IP `192.168.0.164`; API host `192.168.0.81`; mock API received device POSTs. |
| Mock API stopped path | PASS | `/health` failed before uvicorn was started, confirming unreachable-server behavior is reproducible. |
| SIT config startup | PASS | App logs showed `app env: sit`, Supabase URL/key configured, API base URL configured. |
| Supabase initialization | PASS | App logs showed Supabase init completed. |
| Fresh install | PARTIAL | `adb uninstall com.collectiq.ai.sit` returned `DELETE_FAILED_INTERNAL_ERROR`; app was installed over the existing SIT package. |
| Gallery picker | PASS | Android Photo Picker opened and returned a selected image. |
| Gallery image persistence | PASS | Image copied to persistent app storage under `collectiq_gallery`. |
| Gallery analyze | PASS | App posted to `http://192.168.0.81:8000/scanner/analyze`; mock API returned `200 OK`. |
| Save to Portfolio | PASS | Result screen changed to `Saved`; app logged `portfolio updated`. |
| Portfolio visible | PASS | Portfolio showed saved item `Transformers Optimus Prime G1 Figure`, `AUD 260`, `84%`. |
| Restart persistence | PASS | After restart and rerun, Home showed `1 item`, `AUD 260`, top asset restored. |
| Camera permission | PASS | Android permission prompt appeared and foreground camera permission was granted. |
| Camera capture | PASS | Samsung camera opened, captured image, and returned it to PackLox. |
| Camera image persistence | PASS | Image copied to persistent app storage under `collectiq_camera`. |
| Camera analyze | PASS | App posted to `/scanner/analyze`; mock API returned `200 OK`. |
| Upload queue without auth | PASS | Save queued image upload; sync reported no signed-in Supabase session instead of crashing. |
| Sign up | NOT RUN | Requires a disposable SIT test email and inbox verification access. |
| Email verification | NOT RUN | Requires access to the verification email. |
| Login/logout/login again | NOT RUN | Requires a verified SIT account. |
| Cloud portfolio restore | NOT RUN | Requires authenticated Supabase account. |
| Supabase unavailable | NOT RUN | Requires temporary invalid Supabase config or controlled project outage. |
| Image upload failure/retry sync | NOT RUN | Requires authenticated account and controlled Storage policy/bucket failure. |
| Wi-Fi off/on retry | NOT RUN | Not executed to avoid disrupting the active device/network during this pass. |
| API_BASE_URL missing | NOT RUN | Documented command exists; not executed in this pass. |

## Bug Fixed

Real-device restart with persisted portfolio data exposed a Flutter layout
assertion in `lib/features/home/presentation/home_screen.dart`:

`BoxConstraints has a negative minimum width`

The fix clamps available tile width to zero or greater before creating
`SizedBox` children in the home quick actions and compact portfolio snapshot
layout builders.

## Remaining Manual Gaps

- Run authenticated Supabase SIT with a verified disposable test account.
- Verify logout/login restore and no login fields after authenticated login.
- Verify actual Supabase Storage upload, delete, upload failure, and retry sync.
- Verify Supabase unavailable behavior with controlled invalid SIT config.
- Verify Wi-Fi off/on retry on a device where temporary network disruption is acceptable.
- Re-run fresh install after resolving Android package uninstall failure if it repeats.
