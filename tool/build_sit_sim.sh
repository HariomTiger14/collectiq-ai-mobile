#!/usr/bin/env bash
# Canonical SIT simulator build -- the ONE command to build the app with
# every production-shaped capability on: cloud auth/sync/storage, real
# Supabase, and telemetry (Firebase Crashlytics + Analytics + the
# backend ops-feed error lane).
#
# Telemetry is opt-in PER BUILD via dart-defines: a build made without
# the two COLLECTIQ_TELEMETRY_* flags reports nothing at all. That
# opt-in is deliberate (local/dev builds shouldn't pollute crash stats),
# but it also means the flags being missing from a build command is
# indistinguishable from telemetry being broken -- which is why this
# script exists instead of a command pasted from notes.
#
# Secrets come from config/sit.env (gitignored). Usage:
#   tool/build_sit_sim.sh            # build only
#   tool/build_sit_sim.sh --install  # + install/launch on the booted sim
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f config/sit.env ]]; then
    echo "config/sit.env is missing (gitignored; holds SUPABASE_*/API_BASE_URL)." >&2
    exit 1
fi
set -a; . config/sit.env; set +a

flutter build ios --flavor sit --simulator --debug \
  --dart-define=APP_ENV=sit \
  --dart-define=USE_CLOUD_AUTH=true \
  --dart-define=USE_CLOUD_PORTFOLIO_SYNC=true \
  --dart-define=USE_CLOUD_IMAGE_STORAGE=true \
  --dart-define=SUPABASE_ENABLED=true \
  --dart-define=AI_ANALYSIS_PROVIDER="${AI_ANALYSIS_PROVIDER:-mock}" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=COLLECTIQ_TELEMETRY_ENABLED=true \
  --dart-define=COLLECTIQ_TELEMETRY_PROVIDER=firebase

if [[ "${1:-}" == "--install" ]]; then
    booted=$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)
    if [[ -z "$booted" ]]; then
        echo "No booted simulator." >&2
        exit 1
    fi
    xcrun simctl install "$booted" build/ios/iphonesimulator/Runner.app
    xcrun simctl launch "$booted" com.collectiq.ai.sit
fi
