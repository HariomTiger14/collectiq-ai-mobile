# Cloudflare Pages Deployment

CollectIQ AI is a Flutter project with web support under `web/`. Cloudflare
Pages should build the Flutter web app and publish `build/web`.

The Cloudflare Pages root route (`/`) serves the public PackLox SIT website.
Authentication utility pages remain under `/auth/` and must not be removed when
changing public pages.

The PackLox Administration portal is now a standalone static project outside
this mobile app repository. Keep admin UI work in `packlox-admin-portal` and
host it independently, for example at `https://admin.packlox.com`.

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
/auth/reset-password/  Existing password reset page
/auth/callback/        Existing auth callback page
```

Future public pages can be added as route folders under `web/`. Future admin
pages should stay out of this repo and belong to the standalone admin portal.

The build script:

- Fails fast on errors.
- Installs stable Flutter if `flutter` is not already available.
- Runs `flutter pub get`.
- Runs `flutter build web --release`.
- Verifies `build/web/index.html` exists.

Expected build output:

```text
build/web/index.html
build/web/site.css
build/web/auth/reset-password/index.html
```

## Admin Backend Integration

The standalone admin portal calls these PackLox API endpoints:

```text
GET https://api-sit.packlox.com/health
GET https://api-sit.packlox.com/version
GET https://api-sit.packlox.com/admin/ops/summary
GET https://api-sit.packlox.com/admin/pricing/health
POST https://api-sit.packlox.com/admin/pricecharting/import
```

The API must allow browser CORS from:

```text
https://sit.packlox.com
https://admin.packlox.com
http://localhost:3000
http://127.0.0.1:3000
```

Admin API settings now live in the standalone admin portal:

```text
packlox-admin-portal/config.js
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
