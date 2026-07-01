@echo off
setlocal
set "ROOT=%~dp0"
if not defined FLUTTER_BIN set "FLUTTER_BIN=flutter"

call "%ROOT%scripts\load_env.bat" "%ROOT%config\local.env"

set "API_BASE_URL_DEFINE="
if defined API_BASE_URL set "API_BASE_URL_DEFINE=--dart-define=API_BASE_URL=%API_BASE_URL%"

call "%FLUTTER_BIN%" run ^
  --flavor local ^
  --dart-define=APP_ENV=local ^
  --dart-define=AI_ANALYSIS_PROVIDER=mock ^
  %API_BASE_URL_DEFINE% ^
  %*
