# CollectIQ SIT Build Setup

Audit date: 2026-07-01

This setup creates three Android app identities:

| Mode | Android flavor | Installed app name | Cloud behavior |
| --- | --- | --- | --- |
| Local | `local` | CollectIQ Local | Local storage, mock/backend-dev safe, no cloud required. |
| SIT | `sit` | CollectIQ SIT | Non-production Supabase DEV and backend API config can be supplied. |
| Production | `prod` | CollectIQ | Supabase can be enabled only with explicit cloud flags and public config. |

## Config Files

Do not commit real config values.

Committed templates:

- `config/local.env.example`
- `config/sit.env.example`

Ignored local files:

- `config/local.env`
- `config/sit.env`

Create `config/sit.env` from the example and fill in DEV/SIT values:

```bat
SUPABASE_URL=https://YOUR-DEV-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
API_BASE_URL=http://YOUR-LAN-IP:8000
```

`API_BASE_URL` must be reachable from the Android phone. Use the computer's LAN IP, not `127.0.0.1`.

Optional:

```bat
AI_BACKEND_ANALYSIS_ENDPOINT_URL=http://YOUR-LAN-IP:8000/api/analyze
```

Provider API keys must stay server-side. Do not put OpenAI, Supabase service-role, signing, or private provider keys in Flutter config files.

## Run Local

```bat
.\run_local.bat
```

Local passes:

- `--flavor local`
- `APP_ENV=local`
- `AI_ANALYSIS_PROVIDER=mock`

No Supabase config is required. Existing local scan, save, delete, search, filter, sort, and portfolio behavior should remain unchanged.

## Run SIT

```bat
.\run_sit.bat
```

SIT passes:

- `--flavor sit`
- `APP_ENV=sit`
- `USE_CLOUD_AUTH=true`
- `USE_CLOUD_PORTFOLIO_SYNC=true`
- `USE_CLOUD_IMAGE_STORAGE=true`
- `SUPABASE_ENABLED=true`
- `AI_ANALYSIS_PROVIDER=mock`
- optional values from `config/sit.env`

If `SUPABASE_URL` or `SUPABASE_ANON_KEY` is missing, the script prints a warning and the app falls back through the existing safe no-op/missing-config paths. This is intentional for graceful local testing, but Supabase sync will not validate until those values are present.

Before live cloud testing, prepare Supabase with `docs/SUPABASE_LIVE_SIT_SETUP.md` and run:

```bat
.\check_supabase_sit.bat
```

The live checker reads `config/sit.env`, uses only the public anon key, and performs no writes.

## Build SIT APK

```bat
.\build_sit_apk.bat
```

The script builds a debug SIT APK so it can be installed on a phone without production signing:

```text
build\app\outputs\flutter-apk\app-sit-debug.apk
```

## Install On Android Phone

Connect the phone with USB debugging enabled, then run:

```bat
adb install -r build\app\outputs\flutter-apk\app-sit-debug.apk
```

The installed app should appear as **CollectIQ SIT** and can coexist with the local and production package IDs:

- `com.collectiq.ai.local`
- `com.collectiq.ai.sit`
- `com.collectiq.ai`

## Production Safety

`prod` exists as a distinct Android flavor and app name. Production Supabase is
not automatic: it requires `APP_ENV=prod`, the three cloud flags, and
`SUPABASE_URL`/`SUPABASE_ANON_KEY`. This sprint does not enable production AI,
billing, marketplace, subscriptions, or release distribution.

## Verification

Run before using a SIT candidate:

```bat
dart format lib test
flutter analyze
flutter test
python scripts\validate_supabase_setup.py
```

Run `.\check_supabase_sit.bat` when you want to verify the actual DEV/SIT Supabase project, not just committed repository files.
