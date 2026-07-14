# Authentication and Settings Product Language Mapping

## Treatment Classes

| Class | Meaning |
| --- | --- |
| A | Approved component authority can be reused directly |
| B | Approved flow authority exists, but runtime composition still needs implementation |
| C | Current runtime behavior exists and must be preserved |
| D | Legacy runtime pattern to remove or replace |

## Mapping

| Product element | Treatment | Authority or source | Implementation instruction |
| --- | --- | --- | --- |
| Header treatments | A | `PLX-HEADER-1.0.1-approved.json` | Reuse approved component rules |
| Hero treatments | A | `PLX-HERO-1.0.1-approved.json` | Reuse only where appropriate for auth entry |
| Entry tiles | A | `PLX-ENTRY-TILE-1.0-approved.json` | Use for Settings account entry where compatible |
| Button system | A | `PLX-BUTTON-SYSTEM-1.0-approved.json` | Use for primary/secondary/text button hierarchy |
| Settings rows/toggles/status copy | B | Settings S01-S10 | Implement as Settings-specific composition |
| Sign In language | B | Authentication S03 | Separate from Settings |
| Sign Up language | B | Authentication S05 | Separate from Settings |
| Forgot/reset language | B/C | Authentication S06-S07 and web reset runtime | Preserve web reset truth |
| Guest/local language | B/C | Authentication S09 and current local runtime | Signed-out does not mean unusable |
| Account linked language | B/C | Authentication S10 and current signed-in state | Show linked status without embedding credentials |
| Settings embedded credential panel | D | Current `AuthAccessPanel` in `SettingsScreen` | Remove from Settings during implementation |
| Search navigation | Not authorized | No Phase 0-5 shell authority | Do not add |

## Copy Guardrails
Use PackLox naming consistently. Do not surface CollectIQ user-facing language in newly remediated copy unless it is a package or legacy technical identifier. Do not promise cloud backup, sync, export, or deletion states that are not implemented and verified.
