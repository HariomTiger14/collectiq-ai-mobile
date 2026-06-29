# Supabase Auth Test Plan

Use this plan after a Supabase project is configured. The app must remain usable
without authentication throughout all tests.

## Guest mode

1. Run the app without Supabase dart defines.
2. Open Settings.
3. Confirm Guest Mode is active.
4. Scan or import a collectible.
5. Save it to Portfolio.
6. Restart the app and confirm the local portfolio item remains available.

Expected result: no login is required and local portfolio behavior is unchanged.

## Anonymous sign-in

1. Enable Supabase with dart defines.
2. Use the future anonymous sign-in entry point.
3. Confirm Supabase returns a user id and access token.
4. Confirm Settings can show a signed-in account state.
5. Sign out.

Expected result: anonymous auth creates a Supabase session without forcing cloud
sync or changing local portfolio storage.

## Email/password sign-in

1. Enable Email provider in Supabase Auth.
2. Create or invite a test user in Supabase.
3. Run the app with Supabase dart defines.
4. Use the future email/password sign-in entry point.
5. Confirm current user includes the email address.
6. Save a local portfolio item and confirm local-first behavior still works.

Expected result: email/password auth succeeds, but portfolio remains local until
sync is explicitly implemented.

## Sign out

1. Sign in anonymously or with email/password.
2. Sign out from the future account action.
3. Confirm current user is cleared.
4. Confirm Portfolio still shows local items.
5. Confirm Scan, Analyze, Save, Search, Sort, Detail, and Delete still work.

Expected result: sign out ends the Supabase session only. It does not delete or
hide the local portfolio.
