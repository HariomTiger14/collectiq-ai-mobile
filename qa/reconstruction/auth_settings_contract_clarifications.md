# Authentication and Settings Contract Clarifications

| Topic | Status | Contract position |
| --- | --- | --- |
| Direct Sign Up from Settings | Unresolved | Default to Settings -> Sign In/choose method -> Sign Up until product approves a direct Settings sign-up CTA |
| Post-auth destination | Unresolved | Return to previous destination, with Settings fallback; do not force Home by default |
| Account Management scope | Partially unresolved | Account status and sign-out are allowed; profile editing/export/deletion require separate authority |
| Password recovery completion | Resolved for now | Preserve web reset page and current mobile parser behavior |
| Email confirmation presentation | Partially unresolved | Existing callback/controller behavior is authoritative; visual confirmation screen needs implementation evidence |
| Anonymous auth/account upgrade | Unresolved | Do not add upgrade semantics beyond existing repository/controller behavior |
| Account deletion | Blocked | Requires reauth, cooling-off, local/cloud data, and security authority before implementation |
| Local data after sign-out | Resolved | Preserve current behavior; sign-out does not delete local collection data |
| Local/cloud merge | Out of scope | Do not change merge or migration semantics in this program |
| Search tab | Resolved | Not authorized; do not add |
| Embedded auth forms in Settings | Resolved | Remove in implementation; current pattern is legacy |
| Original dirty repository | Resolved | Do not touch `collectiq_ai`; work only in reconstruction repo |
