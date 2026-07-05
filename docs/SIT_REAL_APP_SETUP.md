# CollectIQ SIT Real App Setup

Audit date: 2026-07-01

This guide configures **CollectIQ SIT** as a non-production cloud-connected Android app. Production Supabase uses the same foundation only when explicit production flags and public config are supplied.

Authentication behaviour is defined in `docs/AUTHENTICATION_SPECIFICATION.md`.

## Required Local Config

Create `config/sit.env` from `config/sit.env.example`.

```bat
SUPABASE_URL=https://YOUR-DEV-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
API_BASE_URL=http://YOUR-LAN-IP:8000
```

Do not commit `config/sit.env`. Do not put service-role keys, provider API keys, signing passwords, or private prompts in Flutter config.

## Supabase Checklist

For exact live Supabase console steps, use `docs/SUPABASE_LIVE_SIT_SETUP.md`.

Auth:

- Enable email/password auth in Supabase Auth.
- Decide whether email confirmation is required for SIT testers. If it is
  enabled, sign-up creates the account and the app remains signed out until
  the tester confirms the email and signs in.
- A confirmation email means sign-up reached Supabase successfully. The app
  should show the confirmation-required message, not a connection failure.
- Supabase may return a wrapped user object, a direct user object, an
  `identities`/`confirmation_sent_at` response, or an empty 2xx body after
  sending the confirmation email. CollectIQ SIT treats each of these as
  successful sign-up and keeps the user signed out until confirmation/sign-in.
- The **Resend Confirmation** button appears only after sign-up returns
  confirmation-required or sign-in returns email-not-confirmed. It calls the
  Supabase resend confirmation flow and should show
  `Confirmation email sent. Please check Inbox, Spam, Junk, and Promotions.`
  on success.
- After a successful resend, the button is disabled for 60 seconds and shows
  `Resend available in {seconds}s`.
- If Supabase rate-limits confirmation emails, the app shows
  `Too many confirmation requests. Please wait before trying again.` It uses
  Supabase's `Retry-After` header for the cooldown when present, otherwise it
  falls back to 5 minutes. A rate-limit response does not mean Supabase sent
  another email.
- CollectIQ SIT allows 3 resend attempts per 15 minutes per app session. After
  that it shows
  `Too many confirmation emails requested. Please check your inbox or try again later.`
- Repeating Sign Up with an unconfirmed email may also cause Supabase to send
  another confirmation email; testers should confirm the email and then use
  **Sign In**.
- For faster SIT-only testing, email confirmation can optionally be disabled in
  Supabase Auth settings. Do not treat that as production guidance.
- Email and password are required for real SIT cloud sync.
- Anonymous auth is not used automatically in SIT. Leave it disabled unless a future explicit anonymous/dev test plan requires it.
- For email delivery testing, Gmail aliases such as `yourname+sit1@gmail.com`
  are useful because each alias is treated as a distinct address while still
  arriving in the same mailbox.
- Configure Supabase **Authentication > URL Configuration** for mobile
  confirmation links and Packlox web recovery:
  - Site URL: `https://packlox.com/auth/callback`
  - Redirect URLs:
    - `collectiq-sit://auth/callback`
    - `https://packlox.com/auth/callback`
    - `https://packlox.com/auth/reset-password`
  - Future production redirect, not enabled yet: `collectiq://auth/callback`
- Do not use `localhost` as the mobile confirmation redirect URL. Android
  needs the custom `collectiq-sit` scheme so tapping the email link opens
  CollectIQ SIT.
- If the email link opens a blank browser page instead of returning to the app,
  return to CollectIQ SIT manually and tap **Sign In** after email confirmation.
  Then check **SIT Readiness > Last deep link received** to confirm whether
  Android delivered the callback to the app.

Storage:

- Create bucket `collectiq-portfolio-images`.
- Expected object path: `users/{userId}/portfolio_images/{itemId}.jpg`.
- Add RLS policies allowing signed-in users to insert, update, select, and delete only objects under their own `users/{auth.uid()}/...` prefix.

Portfolio table:

- Create table `portfolio_items`.
- Required columns include `id`, `user_id`, `category`, `title`, `manufacturer`, `series`, `year`, `country`, `estimated_value_low`, `estimated_value_high`, `image_local_path`, `image_storage_path`, `cloud_image_url`, `sync_status`, `last_synced_at`, `raw_json`, `created_at`, and `updated_at`.
- Use the committed primary key on `(id, user_id)`.
- Add RLS policies allowing signed-in users to select, insert, update, and tombstone only rows where `user_id = auth.uid()`.

Static/local validation:

```bat
python scripts\validate_supabase_setup.py
```

Live DEV/SIT validation after `config/sit.env` is filled in:

```bat
.\check_supabase_sit.bat
```

Manual Android deep-link validation:

```bat
.\test_sit_deeplink.bat
```

If `adb` is not on PATH:

```bat
set ADB_PATH=C:\Users\YOUR_NAME\AppData\Local\Android\Sdk\platform-tools\adb.exe
.\test_sit_deeplink.bat
```

## Run SIT

```bat
.\run_sit.bat
```

The script passes:

- `APP_ENV=sit`
- `USE_CLOUD_AUTH=true`
- `USE_CLOUD_PORTFOLIO_SYNC=true`
- `USE_CLOUD_IMAGE_STORAGE=true`
- `SUPABASE_ENABLED=true`
- values loaded from `config/sit.env`

If Supabase keys are missing, the app shows setup-required status and keeps local portfolio behavior available.

## Build And Install

```bat
.\build_sit_apk.bat
adb install -r build\app\outputs\flutter-apk\app-sit-debug.apk
```

The installed app name is **CollectIQ SIT**.

## Test Flow

1. Open Settings.
2. Confirm **SIT Readiness** shows `Environment: SIT`.
3. Confirm Supabase and backend URL status.
4. Sign up with a valid email address and a password of at least 6 characters.
5. If Supabase email confirmation is enabled, confirm the email first, then
   return to the app and sign in.
   If the confirmation email arrives, the app should show
   `Check your email to confirm your account, then sign in.`
   If it does not, check **SIT Readiness > Last auth attempt** for the
   normalized result and safe response metadata.
6. Restart the app and confirm the signed-in user is still shown.
7. Use camera or gallery to choose an image.
8. Analyze the image. Flutter calls the backend through `API_BASE_URL`; it never calls OpenAI directly.
9. Save the result. The item is saved locally first, then queued for cloud sync.
10. Tap **Sync Now** in Settings.
11. Confirm the image appears in `collectiq-portfolio-images`.
12. Confirm metadata appears in `portfolio_items`.
13. Edit the item and sync again; confirm the row updates.
14. Delete the item; confirm the row is tombstoned with `sync_status = deleted`.

## Email Auth Behaviour

| Scenario | Expected app behaviour |
| --- | --- |
| Signed out | Email/password fields plus **Sign Up** and **Sign In** are visible. **Sign Out** is hidden. |
| Sign Up with email confirmation on | Supabase may return a user with no session. The app shows `Check your email to confirm your account, then sign in.`, remains signed out, keeps **Sign In** visible, and hides **Sign Out**. |
| Sign Up returns empty/string 2xx response | The app treats this as confirmation-required success, shows `Check your email to confirm your account, then sign in.`, remains signed out, keeps **Sign In** visible, and hides **Sign Out**. |
| Sign Up with email confirmation off | Supabase returns a session. The app navigates to Home, shows a success snackbar, and Settings shows the signed-in Account panel with **Sign Out**. Cloud sync can use that user id. |
| Forgot Password | The app calls Supabase password recovery for the entered email using `https://packlox.com/auth/reset-password` and shows `Password reset email sent. Please wait before requesting another.` The button is disabled for 60 seconds after a successful request. |
| Forgot Password rate limit | The app shows `Too many reset requests. Please wait a few minutes and try again.` and keeps recovery web-only. |
| Repeat Sign Up before confirming email | Supabase may resend the confirmation email or return user/no-session again. The app shows the same confirmation-required message. |
| Resend Confirmation | The app calls Supabase resend confirmation for the pending email and shows `Confirmation email sent. Please check Inbox, Spam, Junk, and Promotions.` on success. Resend is then disabled for 60 seconds with countdown text. Rate limits show `Too many confirmation requests. Please wait before trying again.` and use Supabase `Retry-After` when present, otherwise a 5 minute fallback cooldown. |
| Sign In before confirming email | The app shows `Please confirm your email before signing in.` and remains signed out. |
| Wrong password or unknown account | The app shows `Invalid email or password.` and remains signed out. |
| Missing Supabase config | The app shows `Supabase configuration is missing or invalid.` and does not attempt email auth. |
| Missing anon key response | The app shows `Supabase anon key is missing from SIT config.` |
| Internet off or Supabase unreachable | The app shows `Unable to reach Supabase. Check your internet connection.` This wording is reserved for real network failures. |
| Restart after sign-in | The cached session is restored only if valid. Expired or invalid sessions are cleared and show `Session expired. Please sign in again.` |
| Sign Out | Supabase sign-out is called, the local auth session is cleared, and the on-device portfolio remains. |
| Same device, different user | After User A signs out, User B can sign in and cloud sync uses User B's user id. Local unsynced items remain on device and must not be deleted by auth changes. |
| Email confirmation link opens app | Android opens CollectIQ SIT through `collectiq-sit://auth/callback`. If Supabase includes session tokens, the app validates and stores the session, then shows `Email confirmed successfully.` If no session is returned, it shows `Email confirmed. Please sign in.` |
| Password recovery link opens browser | The browser opens `https://packlox.com/auth/reset-password`, reads Supabase recovery tokens from the URL, updates the password through Supabase, and shows `Password updated successfully.` plus `Return to the Packlox app and sign in with your new password.` |
| Invalid or expired email confirmation link | The app shows `This confirmation link is invalid or expired. Please request a new confirmation email.` |

## Packlox Web Auth Pages

The repository includes minimal static browser pages:

```text
web/auth/callback/index.html
web/auth/reset-password/index.html
web/auth/config.js
```

Production hosting should serve them as:

```text
https://packlox.com/auth/callback
https://packlox.com/auth/reset-password
```

Before deployment, provide public Supabase config in `web/auth/config.js` or replace it during the host build/deploy step:

```js
window.PACKLOX_AUTH_CONFIG = {
  supabaseUrl: 'https://YOUR-PROJECT.supabase.co',
  supabaseAnonKey: 'YOUR_PUBLIC_ANON_KEY',
};
```

Only the public anon key belongs here. Never put a service-role key, password, access token, refresh token, or tester secret in this file.

Password recovery is web-only. If tapping a reset password email opens the
Android app, the link was generated with the wrong redirect URL. Check that the
Forgot Password request includes `https://packlox.com/auth/reset-password`, that
Supabase Auth URL Configuration includes that URL, and that the tester is using
a newly generated recovery email.

CollectIQ SIT cannot read the exact generated recovery email link from the
Supabase anon recover endpoint. To diagnose the actual link, inspect the
received reset email or the Supabase email template/logs. In the app, use
**SIT Readiness > Password recovery redirect** to confirm the exact redirect URL
the app supplied to Supabase when **Forgot Password** was tapped.

## Auth Diagnostics

CollectIQ SIT normalizes Supabase Auth responses through one contract before
the Settings UI chooses a message. In SIT, **SIT Readiness** shows the last auth
attempt with only safe metadata:

- action
- HTTP status
- normalized result
- response body type
- top-level keys only
- timestamp

It also shows the last auth deep link callback metadata:

- received yes/no
- scheme
- host
- path
- query keys only
- callback result
- callback error message, if Supabase supplied one

The panel never shows access tokens, refresh tokens, passwords, anon keys, or
the full response body.

## Backend AI

Start the FastAPI backend so the Android phone can reach `API_BASE_URL`.

For deployment/run details, use `docs/BACKEND_SIT_DEPLOYMENT.md`.

If backend AI is unreachable, the app shows:

```text
AI backend is not reachable. Check your internet/backend setup.
```

## Known Limitations

- Production requires explicit cloud flags and Supabase public config.
- The app still has local-first behavior; cloud failure must not delete local data.
- Invalid or empty email/password input is rejected locally before Supabase is called.
- With email confirmation enabled, successful sign-up shows an email
  confirmation message and keeps Sign In available. Sign Out appears only after
  a confirmed sign-in session exists.
- Sign Out appears only for a real email/password session. Anonymous/dev sessions are labelled separately.
- Marketplace, subscriptions, trending, and global reference search remain out of scope.
- Live Supabase validation requires real DEV project credentials and phone/network access.
