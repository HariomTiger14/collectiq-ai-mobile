# PackLox App Icon Branding QA

Date: 2026-07-19
Branch: rebuild/product-language-v1
Scope: Launcher/app icon artwork and display-name metadata

## Authority

- Brand authority: `C:\Users\hario\Desktop\projects\packlox-design-platform\incoming_authority\reset_2026_07_18\ChatGPT Image Jul 18, 2026, 12_06_58 AM.png`
- Authority dimensions: 1536 x 1024
- Board section used: `04 APP ICON`
- Board app-icon reference crop: x=1195, y=115, width=125, height=125
- Production geometry source: approved Brand v2 P emblem from the same Brand v2 authority system, using the existing standalone PackLox emblem asset already present in the Flutter asset pack.

## Source Findings

- Android launcher icon comes from `android/app/src/main/AndroidManifest.xml` via `android:icon="@mipmap/ic_launcher"`.
- Android adaptive icon is configured by:
  - `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
  - `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
  - `android/app/src/main/res/drawable/ic_launcher_foreground.*`
  - `android/app/src/main/res/values/colors.xml`
- The old Android foreground was `android/app/src/main/res/drawable/ic_launcher_foreground.xml`, a CollectIQ-style green/white vector mark.
- Legacy Android density PNGs existed under `android/app/src/main/res/mipmap-*`.
- iOS app icons existed under `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
- Web launcher icons existed under `web/favicon.png` and `web/icons/`.
- Android display names were defined by `android/app/src/*/res/values/strings.xml`.
- iOS display name was defined by `ios/Runner/Info.plist`.
- Web install/display names were defined by `web/manifest.json`.

## Generated Assets

- `assets/packlox/brand/packlox_brand_v2_app_icon_authority.png` - 1024 x 1024
- `assets/packlox/brand/packlox_brand_v2_app_icon_foreground_authority.png` - 432 x 432 transparent foreground
- `android/app/src/main/res/drawable/ic_launcher_foreground.png` - 432 x 432 transparent foreground
- Android legacy launcher PNGs:
  - `mipmap-mdpi/ic_launcher.png` - 48 x 48
  - `mipmap-hdpi/ic_launcher.png` - 72 x 72
  - `mipmap-xhdpi/ic_launcher.png` - 96 x 96
  - `mipmap-xxhdpi/ic_launcher.png` - 144 x 144
  - `mipmap-xxxhdpi/ic_launcher.png` - 192 x 192
- iOS AppIcon PNGs regenerated for every size listed in `Contents.json`, including 1024 x 1024 marketing icon.
- Web favicon/PWA PNGs regenerated:
  - `web/favicon.png` - 32 x 32
  - `web/icons/Icon-192.png` - 192 x 192
  - `web/icons/Icon-512.png` - 512 x 512
  - `web/icons/Icon-maskable-192.png` - 192 x 192
  - `web/icons/Icon-maskable-512.png` - 512 x 512

## Branding Notes

- Old CollectIQ launcher foreground artwork was removed.
- The launcher background color changed from `#10243E` to Brand v2 dark surface `#0B111A`.
- Package names, flavor names, Android application IDs, and iOS bundle IDs were not changed.
- Android display names now resolve as:
  - prod/main fallback: `PackLox`
  - local/dev flavor: `PackLox Dev`
  - SIT flavor: `PackLox SIT`
- iOS display name is now `PackLox`.
- Web manifest name and short name are now `PackLox`.
- Auth logic, backend code, Supabase config, and secrets were not modified.

## Validation

- `flutter analyze`: PASS
- `flutter test test/auth_presentation_test.dart`: PASS
- `flutter build apk --debug --flavor sit`: PASS
- Built APK: `build/app/outputs/flutter-apk/app-sit-debug.apk`
- APK badging confirms `application-label:'PackLox SIT'`.
- APK badging confirms package name remains `com.collectiq.ai.sit`.
- Installed on connected Samsung device `RZ8R213M8ZL`: PASS
- APK badging confirms `application-icon-*` entries use `res/mipmap-anydpi-v26/ic_launcher.xml`.
- APK contents include:
  - `res/mipmap-anydpi-v26/ic_launcher.xml`
  - `res/mipmap-anydpi-v26/ic_launcher_round.xml`
  - `res/drawable/ic_launcher_foreground.png`
  - all legacy `res/mipmap-*-v4/ic_launcher.png` density assets
- `git diff --check`: PASS
- No dedicated app-label/flavor metadata test was found in the existing test suite; label verification used Android APK badging inspection.

## Screenshot Evidence

No launcher/app-switcher screenshot is retained. An attempted recents screenshot opened an unrelated app and included personal content, so it was deleted and excluded from QA evidence.

Manual launcher verification should confirm the installed SIT app icon visually shows the PackLox Brand v2 P emblem on the dark PackLox background.

## Polish Update - Optical Centering

Manual SIT review found the installed Android launcher icon read as slightly left-shifted inside the rounded-square launcher mask. The current icon source was traced to the Brand v2 authority board section `04 APP ICON`, then into:

- `assets/packlox/brand/packlox_brand_v2_app_icon_authority.png`
- `assets/packlox/brand/packlox_brand_v2_app_icon_foreground_authority.png`
- `android/app/src/main/res/drawable/ic_launcher_foreground.png`
- Android `mipmap-*` launcher PNG fallbacks

The approved Brand v2 P emblem geometry was retained. No old CollectIQ artwork, auth UI artwork, backend files, secrets, package IDs, or app display-name rules were changed by this polish pass.

### Optical Adjustment

- Previous adaptive foreground visible bounds: left 113, top 98, right padding 118, bottom padding 102 on a 432 x 432 canvas.
- Polished adaptive foreground visible bounds: left 118, top 100, right padding 113, bottom padding 100 on a 432 x 432 canvas.
- Applied optical placement shift: +5 px right and +2 px down on the adaptive foreground canvas.
- Rationale: the Brand v2 P emblem has heavier visual mass on the left stem, so the mark needs a slight rightward optical correction rather than strict mathematical centering.
- Android adaptive background remains Brand v2 dark surface `#0B111A`.
- 1024 source was regenerated from the shifted foreground over the Brand v2 dark background.
- Android fallback launcher PNGs regenerated from the polished 1024 source at mdpi, hdpi, xhdpi, xxhdpi, and xxxhdpi.

### Polish Evidence

- Sanitized preview: `qa/branding_app_icon/screenshots/APP_ICON_POLISH_PREVIEW.png`
- Preview dimensions: 1600 x 820
- The preview shows the approved reference mark and the polished launcher source with center guides and padding notes.

### Polish Validation

- `flutter analyze`: PASS
- `flutter build apk --debug --flavor sit`: PASS
- Built APK: `build/app/outputs/flutter-apk/app-sit-debug.apk`
- Installed on connected Samsung device `RZ8R213M8ZL`: PASS
- APK badging confirms `application-label:'PackLox SIT'`.
- APK badging confirms package name remains `com.collectiq.ai.sit`.
- APK badging confirms launcher icon resource remains `res/mipmap-anydpi-v26/ic_launcher.xml`.
- Launcher/home-screen screenshot was not captured automatically to avoid collecting personal device content. Visual owner verification on-device is still recommended.
