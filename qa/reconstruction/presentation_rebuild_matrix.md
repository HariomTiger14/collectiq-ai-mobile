# File classification matrix

| Class | Paths/modules | Approx. entries | Rule |
|---|---|---:|---|
| Preserve | `lib/**/domain/**`, `lib/**/data/**`, repositories, services, controllers, `core/network`, `core/cloud`, `core/supabase`, scanner session/analyzer/image/storage logic, environment config | 12 path groups | No presentation sprint edits |
| Presentation rebuild candidate | `lib/features/**/presentation/**/*screen.dart`, `**/*page.dart`, onboarding, Settings `AuthAccessPanel`, legacy feature widgets, old gradient/glass/settings primitives | 10 path groups | Replace view composition while retaining callbacks/providers |
| Shared implementation candidate | `lib/core/ui/product_language/**`, `core/navigation/app_shell.dart`, system-bar/safe-area helpers, shared loading/error primitives, theme composition | 5 path groups | Extend only from approved contracts |
| High risk | `android/app/build.gradle.kts`, manifests/MainActivity, iOS bundle/deep links, Supabase URLs/redirects, `cloud_storage_paths.dart`, schema/migrations, flavour scripts, env vars, signing | 10 path groups | Separate sprint and explicit approval |

Classification total: **37 path/module groups** (12 preserve, 10 presentation, 5 shared, 10 high-risk). These are control groups, not a count of Dart files.

Production files changed by this baseline sprint: **zero**.

