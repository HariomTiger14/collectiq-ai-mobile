# Cloudflare Pages Deployment

CollectIQ AI is a Flutter project with web support under `web/`. Cloudflare
Pages should build the Flutter web app and publish `build/web`.

The Cloudflare Pages root route (`/`) serves the public PackLox SIT website.
The PackLox SIT Administration dashboard is served from `/admin/`.
Authentication utility pages remain under `/auth/` and must not be removed when
changing either public or admin pages.

The dashboard reads backend health data from `https://api-sit.packlox.com`.

## Cloudflare Pages Settings

Use these settings in Cloudflare Pages:

```text
Build command: ./scripts/cloudflare_pages_build.sh
Build output directory: build/web
Root directory: /
```

## Published Routes

```text
/                      Public PackLox website
/admin/                PackLox Administration dashboard
/auth/reset-password/  Existing password reset page
/auth/callback/        Existing auth callback page
```

Future public pages can be added as route folders under `web/`. Future admin
pages should stay under `web/admin/`. Keep dashboard assets in `web/admin/` so
the public root page can evolve without replacing existing auth pages.

The build script:

- Fails fast on errors.
- Installs stable Flutter if `flutter` is not already available.
- Runs `flutter pub get`.
- Runs `flutter build web --release`.
- Verifies `build/web/index.html` exists.

Expected build output:

```text
build/web/index.html
build/web/admin/index.html
build/web/admin/config.js
build/web/admin/styles.css
build/web/admin/dashboard.js
build/web/site.css
build/web/auth/reset-password/index.html
```

## Dashboard Backend Integration

The `/admin/` dashboard calls these PackLox API endpoints on page load:

```text
GET https://api-sit.packlox.com/health
GET https://api-sit.packlox.com/version
```

`/health` refreshes every 30 seconds. `/version` loads once per page load.

The API must allow browser CORS from:

```text
https://sit.packlox.com
https://admin.packlox.com
http://localhost:3000
http://127.0.0.1:3000
```

Dashboard API settings live in:

```text
web/admin/config.js
```

## Local Verification

On Windows PowerShell, using the local Flutter SDK path:

```powershell
C:\Users\hario\Desktop\flutter\bin\flutter.bat pub get
C:\Users\hario\Desktop\flutter\bin\flutter.bat build web --release
Test-Path build\web\index.html
```

On macOS/Linux or Windows shells where `flutter` is on `PATH`:

```bash
flutter pub get
flutter build web --release
test -f build/web/index.html
```
