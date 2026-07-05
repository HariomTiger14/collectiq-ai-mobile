# PackLox Real-Device SIT Commands

Use these commands from the repo root on Windows.

## 1. Required SIT Values

Create `config/sit.env` from `config/sit.env.example`.

Required values:

```bat
SUPABASE_URL=https://ljrkhamgbgtsicqdisos.supabase.co
SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

`APP_ENV=sit` defaults backend analysis to `https://api-sit.packlox.com`.
Set `API_BASE_URL` only when intentionally overriding SIT to a local backend.

Do not commit `config/sit.env`. Do not place service-role keys or provider API
secrets in Flutter config.

Confirm values without exposing the anon key:

```powershell
Get-Content config\sit.env | ForEach-Object {
  if ($_ -match '^SUPABASE_ANON_KEY=(.*)$') {
    "SUPABASE_ANON_KEY=<redacted length=$($Matches[1].Length)>"
  } else {
    $_
  }
}
```

## 2. Optional Local Analyzer API Override

Skip this section for the live SIT backend.

Set this only when validating against a backend running on your PC:

```bat
API_BASE_URL=http://YOUR-PC-LAN-IP:8000
```

```powershell
cd backend
$env:BACKEND_ENV="sit"
$env:AI_PROVIDER="mock"
$env:PRICING_PROVIDER="mock"
py -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

In a second terminal, verify the PC endpoint:

```powershell
Invoke-WebRequest -UseBasicParsing -Uri http://YOUR-PC-LAN-IP:8000/health
```

Expected: JSON with `"ai_provider":"mock"`.

## 3. Confirm Android Device

```powershell
adb devices
adb -s DEVICE_ID shell getprop ro.product.model
adb -s DEVICE_ID shell ip addr show wlan0
```

The phone and `API_BASE_URL` host must be on the same LAN.

## 4. Fresh Install And Run

Fresh uninstall:

```powershell
adb -s DEVICE_ID uninstall com.collectiq.ai.sit
```

Run SIT from source:

```powershell
.\run_sit.bat -d DEVICE_ID
```

Equivalent expanded command:

```powershell
C:\Users\hario\Desktop\flutter\bin\flutter.bat run `
  --flavor sit `
  -d DEVICE_ID `
  --dart-define=APP_ENV=sit `
  --dart-define=USE_CLOUD_AUTH=true `
  --dart-define=USE_CLOUD_PORTFOLIO_SYNC=true `
  --dart-define=USE_CLOUD_IMAGE_STORAGE=true `
  --dart-define=SUPABASE_ENABLED=true `
  --dart-define=AI_ANALYSIS_PROVIDER=mock `
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL `
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

With no `API_BASE_URL` override, scanner analysis calls:

```text
POST https://api-sit.packlox.com/analyze
```

Build a release SIT APK with the same auth defines:

```powershell
C:\Users\hario\Desktop\flutter\bin\flutter.bat build apk `
  --release `
  --flavor sit `
  --dart-define=APP_ENV=sit `
  --dart-define=USE_CLOUD_AUTH=true `
  --dart-define=USE_CLOUD_PORTFOLIO_SYNC=true `
  --dart-define=USE_CLOUD_IMAGE_STORAGE=true `
  --dart-define=SUPABASE_ENABLED=true `
  --dart-define=SUPABASE_URL=https://ljrkhamgbgtsicqdisos.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Expected output:

```text
build\app\outputs\flutter-apk\app-sit-release.apk
```

If an APK was built with only `APP_ENV=sit`, Forgot Password will show the
missing Supabase configuration state because the URL, anon key, and
`SUPABASE_ENABLED=true` were not compiled into the app.

## 5. Useful Logs

```powershell
adb -s DEVICE_ID logcat -c
adb -s DEVICE_ID logcat PackLox:* CollectIQ:* flutter:* Supabase:* *:S
```

For broader scan/auth debugging:

```powershell
adb -s DEVICE_ID logcat | Select-String -Pattern "Supabase|Auth|ImageSync|portfolio|scanner|BackendAI|Dio|HTTP"
```

## 6. Manual Flow Checklist

- Fresh install opens PackLox SIT.
- Sign up with a test email.
- Verify email from inbox.
- Log in.
- Force-stop and reopen; session restores.
- Gallery image analyzes through mock API.
- Camera image analyzes through mock API.
- Save to Portfolio.
- Portfolio image is visible.
- Force-stop and reopen; image is still visible.
- Log out.
- Log in again.
- Portfolio sync restores cloud data.

## 7. Failure-Path Commands

API missing:

```powershell
ren config\sit.env sit.env.tmp
.\run_sit.bat -d DEVICE_ID
ren config\sit.env.tmp sit.env
```

Mock API stopped: stop the `uvicorn` terminal with `Ctrl+C`, then run gallery
or camera analysis.

Wi-Fi off/on:

```powershell
adb -s DEVICE_ID shell svc wifi disable
adb -s DEVICE_ID shell svc wifi enable
```

Supabase unavailable: run once with invalid public Supabase config in a
temporary command or temporary local env file. Do not commit it.

Image upload failure: temporarily use a Supabase Storage policy/bucket state
that denies uploads, save an item, verify failed/retryable sync, then restore
the policy and retry sync.

## 8. Quality Commands

```powershell
C:\Users\hario\Desktop\flutter\bin\flutter.bat analyze
C:\Users\hario\Desktop\flutter\bin\flutter.bat test --reporter compact
```
