# Auth Phase 6A Measurements

Authority frame basis: approved Authentication crops are narrow board crops, mostly 133 x 385. Runtime uses responsive Flutter layout with a 420 logical px max form width and scrollable safe-area composition.

## Sign In

- Top inset: SafeArea top plus 16 logical px outer padding.
- Header: `PackLoxHeader` at first viewport top, reusing Header v1.0.1.
- Identity placement: identity panel immediately below subtitle, full width of constrained form.
- Title/subtitle: title in header, explanatory subtitle below header before fields.
- Email field: first input, email keyboard, no whitespace input.
- Password field: second input, obscured by default.
- Visibility icon: trailing icon button inside password field, labelled Show/Hide password.
- Forgot password: right-aligned text action directly below password field.
- Primary button: full-width PackLox primary button below message area.
- Sign Up entry: full-width secondary PackLox button below primary.
- Guest return: full-width quiet button plus guest note.
- Error placement: form-level message block after forgot-password action and before primary action.
- Keyboard clearance: `SingleChildScrollView` pads bottom by keyboard inset.
- First viewport: header, subtitle, identity, email, password, forgot password, and first CTA are reachable by scroll on 320 px width.

## Sign Up

- Title/subtitle: Create Account header copy, switches to Check Your Email only after controller confirmation state.
- Fields: email and password only; no name, username, phone, or confirmation fields added.
- Password requirements: honest minimum 6-character helper matching controller validation.
- Terms/privacy: omitted because no real links/contracts exist in current runtime.
- Primary action: full-width Create Account button.
- Sign In entry: Back to Sign In secondary button.
- Confirmation handoff: controller `confirmationRequired` state renders email-verification panel with real pending email.

## Forgot Password

- Field: email only.
- Explanation: reset continues through existing secure web email flow.
- Submit: Send Reset Email button invokes `sendPasswordResetEmail`.
- Success state: replaces input with secure web reset handoff tile.
- Return: Back to Sign In button.

## Email Verification

- Icon: email-read identity icon.
- Email destination: real `pendingConfirmationEmail` or submitted email.
- Resend: invokes controller resend confirmation once per tap.
- Continue/return: Back to Sign In only; no forced deep-link navigation.

## Reset Password

- Mobile app does not implement new-password fields.
- Approved handoff is represented by Forgot Password success copy and the existing `web/auth/reset-password` runtime contract.

## Guest Mode

- Continuation action: Continue as Guest returns to the previous route.
- Explanation: guest note states scanning and Portfolio remain local without account.
- Account benefits: cloud sync is mentioned as optional, not mandatory.

## Linked Account

- Signed-in acknowledgement remains driven by `AuthState.isSignedIn`.
- Settings can sign out from real signed-in state.
- No fake account identity is displayed.
