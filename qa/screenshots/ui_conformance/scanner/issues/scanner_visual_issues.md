# Scanner Visual Issues

## UI-AUDIT-SCANNER-001

Severity: Medium

Issue: Scanner workspace and result states are runtime-captured but lack direct approved visual references.

Recommended correction: Approve workspace, result, and result-action references alongside the existing Scan Hub reference.

## UI-AUDIT-SCANNER-002

Severity: Medium

Issue: Camera entry currently reaches an Android platform permission sheet after the app action.

Recommended correction: Document platform permission as accepted evidence or add an approved app pre-permission state before invoking the platform dialog.
