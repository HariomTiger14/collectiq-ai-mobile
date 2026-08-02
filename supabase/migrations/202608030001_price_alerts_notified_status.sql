-- Price-alert "notify once per trigger" lifecycle (fixes 6-hourly re-push spam).
--
-- The push dispatcher previously re-sent an FCM push for EVERY row still in
-- status='triggered' on each run, so a single trigger kept re-notifying forever.
-- Fix: after a successful push the dispatcher flips the alert to 'notified', and
-- the server evaluator re-arms it back to 'active' once its condition clears.
-- Add 'notified' to the status check and a notified_at stamp for observability.

alter table public.price_alerts
  drop constraint if exists price_alerts_status_check;

alter table public.price_alerts
  add constraint price_alerts_status_check
  check (status in ('active', 'triggered', 'notified', 'paused'));

alter table public.price_alerts
  add column if not exists notified_at timestamptz;
