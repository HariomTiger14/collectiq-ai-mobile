# CollectIQ AI Known Limitations

This file should be shared with internal testers so beta feedback is grounded in
the current product state.

## Mock/default Mode

- The app defaults to mock AI and mock pricing for safe local testing.
- Mock results are useful for workflow validation, not final recognition
  accuracy.
- Some repeated or approximate collectible details can appear in mock mode.

## Real AI

- Real AI recognition requires the backend to be configured and reachable.
- Flutter must never store provider API keys.
- Backend OpenAI/Gemini-style providers are controlled by server-side env vars.
- AI can still be wrong, especially with glare, blur, cropped photos, or
  multiple collectibles in one image.

## Real Pricing

- Real pricing requires backend provider configuration.
- eBay, TCGPlayer, PriceCharting, or future providers must be called from the
  backend only.
- Price estimates can vary by condition, grade, region, currency, and listing
  quality.
- Pricing confidence and comparable sales should be reviewed by testers.

## Cloud Sync

- Cloud sync requires Supabase URL/key configuration and a test Supabase
  project with schema, RLS, and storage policies applied.
- The app remains local-first. Local save should work even if sync fails.
- Conflict handling is intentionally conservative for beta.
- Images may continue using local paths until cloud upload completes.

## Authentication

- Sign-in is optional.
- Local guest mode is expected and supported.
- Email/password auth requires Supabase configuration.
- Google and Apple sign-in remain placeholders unless explicitly configured in
  a later sprint.

## Billing

- Google Play Billing requires Play Console product setup.
- Use test products and license testers during closed beta.
- Free/local mode must remain usable if billing is unavailable.
- Purchase state should be treated as beta/test only until product IDs and
  entitlement validation are production-ready.

## Notifications and Alerts

- Price alerts are local-first.
- Android notification permission may be required on Android 13+.
- Backend push notifications are not implemented yet.
- Alerts depend on local evaluation and available pricing/history data.

## Native Camera/Gallery

- Native picker behavior varies by Android version and device manufacturer.
- Camera/gallery validation should include physical devices, cancellation, and
  permission-denied paths.
- If a picker issue occurs, attach logcat around the exact timestamp.

## Telemetry and Logs

- Telemetry is no-op by default unless configured.
- Logs and telemetry must not include API keys, image paths, email addresses, or
  personal collectible content.
- Debug logs are useful for beta triage, but release builds should avoid noisy
  or sensitive output.

## UI and Accessibility

- The app is mobile-first for Android.
- Large-font and small-device layout should still be checked manually.
- Charts and visual analytics include labels, but advanced charting is future
  work.

## Backend Availability

- Backend validation requires the FastAPI service to be running.
- Offline mode should be tested separately from backend-enabled mode.
- Backend errors should appear as friendly app errors or diagnostics, not
  crashes.
