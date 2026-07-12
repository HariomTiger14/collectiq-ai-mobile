# Legacy presentation inventory and deprecation policy

Approved Product Language implementations win. Map replacements before use; mark old widgets deprecated in a record/comment only after a canonical replacement exists. Do not delete until no route, test, import or evidence tool depends on the old implementation. Avoid two editable canonical versions. Removal happens only in focused cleanup sprints with history and migration notes preserved.

| Legacy family | Current paths | Intended replacement |
|---|---|---|
| Gradient/glass/settings primitives | `core/widgets/gradient_header.dart`, `glass_card.dart`, `modern_settings_row.dart` | approved PL families as released |
| Old design/theme/layout | `core/design_system/**`, `core/theme/design_system.dart`, feature visual themes | PL tokens and approved utilities |
| Home-local dashboard widgets | `features/home/presentation/**` | approved Home compositions |
| Auth embedded panel | `AuthAccessPanel` inside Settings | standalone approved auth screens reusing controller |
| Scanner duplicates | both `scanner_screen.dart`, workspace/result pages and inline widgets | one documented canonical presentation per S01–S10 state |
| Portfolio/detail local widgets/dialogs | `features/portfolio/presentation/**` | approved portfolio/detail families |
| Placeholder | `shared/widgets/app_placeholder_screen.dart` | approved shared system states |

