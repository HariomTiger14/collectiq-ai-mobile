@echo off
setlocal
set "ROOT=%~dp0"
cd /d "%ROOT%" || exit /b 1

if /i "%FLUTTER_BIN%"=="flutter" set "FLUTTER_BIN="
if not defined FLUTTER_BIN (
  for /f "delims=" %%F in ('where flutter.bat 2^>nul') do (
    if not defined FLUTTER_BIN set "FLUTTER_BIN=%%F"
  )
)
if not defined FLUTTER_BIN set "FLUTTER_BIN=flutter.bat"

call "%ROOT%scripts\load_env.bat" "%ROOT%config\sit.env"

set "SUPABASE_URL_DEFINE="
if defined SUPABASE_URL set "SUPABASE_URL_DEFINE=--dart-define=SUPABASE_URL=%SUPABASE_URL%"

set "SUPABASE_ANON_KEY_DEFINE="
if defined SUPABASE_ANON_KEY set "SUPABASE_ANON_KEY_DEFINE=--dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%"

set "API_BASE_URL_DEFINE="
if defined API_BASE_URL set "API_BASE_URL_DEFINE=--dart-define=API_BASE_URL=%API_BASE_URL%"

set "AI_BACKEND_DEFINE="
if defined AI_BACKEND_ANALYSIS_ENDPOINT_URL set "AI_BACKEND_DEFINE=--dart-define=AI_BACKEND_ANALYSIS_ENDPOINT_URL=%AI_BACKEND_ANALYSIS_ENDPOINT_URL%"

if not defined SUPABASE_URL echo [CollectIQ SIT] SUPABASE_URL is not set. Cloud services will fall back safely.
if not defined SUPABASE_ANON_KEY echo [CollectIQ SIT] SUPABASE_ANON_KEY is not set. Cloud services will fall back safely.
if not defined API_BASE_URL echo [CollectIQ SIT] API_BASE_URL is not set. Backend AI will use https://api-sit.packlox.com.

call "%FLUTTER_BIN%" run ^
  --flavor sit ^
  --dart-define=APP_ENV=sit ^
  --dart-define=USE_CLOUD_AUTH=true ^
  --dart-define=USE_CLOUD_PORTFOLIO_SYNC=true ^
  --dart-define=USE_CLOUD_IMAGE_STORAGE=true ^
  --dart-define=SUPABASE_ENABLED=true ^
  --dart-define=AI_ANALYSIS_PROVIDER=mock ^
  %SUPABASE_URL_DEFINE% ^
  %SUPABASE_ANON_KEY_DEFINE% ^
  %API_BASE_URL_DEFINE% ^
  %AI_BACKEND_DEFINE% ^
  %*
