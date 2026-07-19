# S03 OTP Runtime Compatibility QA

Date: 2026-07-19
Branch: rebuild/product-language-v1
Scope: Authentication S03 - Verify Email / OTP Code

## Result

Status: NEEDS DEVICE RECHECK AFTER LOCAL VALIDATION

The S03 OTP field has been updated for runtime compatibility with the Supabase SIT OTP observed during manual testing. The frozen S03 design contract originally assumed a 6-digit OTP, but SIT email delivery now provides a longer numeric token. The Flutter implementation now uses `authEmailOtpLength = 8` so the Verify action remains disabled until exactly 8 digits are entered.

## Changes Covered

- OTP entry accepts the full 8-digit Supabase SIT email token length.
- Verify remains disabled for empty, partial, non-digit, or old 6-digit completion input.
- Verify is enabled only when the field contains exactly 8 digits.
- No auto-submit was introduced.
- Existing S03 resend cooldown, 5-attempt lockout, Change Email route, and backend `verifyEmailOtp` call are preserved.
- The OTP input no longer uses a floating label. A visible label appears above the field and the field uses an `8-digit code` hint, avoiding label/border/text overlap.
- OTP text now uses explicit high-contrast dark text while typing: `#0B111A`.
- OTP hint text uses muted gray `#64748B`; the cursor uses `#0066CC`; selection color uses translucent PackLox blue.

## Product Note

This is a runtime compatibility adjustment, not a broader product redesign. The only behavioral compatibility change is OTP length alignment with the Supabase SIT token. Safe error copy and no-account-enumeration behavior remain unchanged.

## Runtime Evidence

No new device screenshot was captured in this local pass. Manual SIT recheck should confirm:

- The full 8-digit OTP can be entered.
- Typed digits are visible while the field is focused against the light OTP field background.
- No OTP field label overlap appears with the keyboard open.
- Verify enables only after exactly 8 digits.
