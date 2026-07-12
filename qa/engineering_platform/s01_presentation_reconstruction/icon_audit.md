# S01 icon fidelity audit

Foundation specifies rounded line icons. No exact approved vector assets exist in the inspected project, and no new dependency is justified.

| Icon | Reference | Current source | Audit | Reconstruction decision |
|---|---|---|---|---|
| Notification | Simple rounded outline bell | `Icons.notifications_outlined` | Family correct; optical size must stay subordinate | Retain at 22 inside 48 target. |
| Hero | Four scan corners with circular centre | `Icons.center_focus_strong_outlined` | Built-in line glyph is the closest existing match | Retain, explicitly sized/aligned. |
| Camera | Rounded outline camera | `Icons.photo_camera_outlined` | Close match | Retain. |
| Gallery | Stacked photo outline | `Icons.photo_library_outlined` | Close match | Retain. |
| Sample | Outline laboratory flask | `Icons.science_outlined` | Close match | Retain. |
| Home | Reference nav uses compact home glyph | Shared `Icons.home` | Filled shared-nav family; differs from content line icons | Shared ownership; verify, do not alter locally. |
| Portfolio | Compact archive/container | Shared `Icons.inventory_2` | Filled shared-nav family | Shared ownership; verify. |
| Scan | Camera/scan active symbol | Shared `Icons.camera_alt` | Filled selected treatment | Shared ownership; verify. |
| Settings | Compact gear | Shared `Icons.settings` | Filled shared-nav family | Shared ownership; verify. |

S01 presentation uses one coherent built-in Material outlined family. Navigation remains its existing internally consistent shared family; mixing is intentional across component domains, not within S01 content.
