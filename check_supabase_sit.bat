@echo off
setlocal
set "ROOT=%~dp0"

call "%ROOT%scripts\load_env.bat" "%ROOT%config\sit.env"

if not defined SUPABASE_URL echo [CollectIQ SIT] SUPABASE_URL is not set.
if not defined SUPABASE_ANON_KEY echo [CollectIQ SIT] SUPABASE_ANON_KEY is not set.

py "%ROOT%scripts\check_live_supabase_sit.py" %*
