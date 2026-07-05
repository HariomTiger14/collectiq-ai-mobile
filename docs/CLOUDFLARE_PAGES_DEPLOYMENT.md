# Cloudflare Pages Deployment

CollectIQ AI is a Flutter project with web support under `web/`. Cloudflare
Pages should build the Flutter web app and publish `build/web`.

## Cloudflare Pages Settings

Use these settings in Cloudflare Pages:

```text
Build command: ./scripts/cloudflare_pages_build.sh
Build output directory: build/web
Root directory: /
```

The build script:

- Fails fast on errors.
- Installs stable Flutter if `flutter` is not already available.
- Runs `flutter pub get`.
- Runs `flutter build web --release`.
- Verifies `build/web/index.html` exists.

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
