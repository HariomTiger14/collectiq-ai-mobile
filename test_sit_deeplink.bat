@echo off
setlocal

set "ADB_EXE=%ADB_PATH%"
if "%ADB_EXE%"=="" set "ADB_EXE=adb"

echo Testing CollectIQ SIT auth deep link...
echo Using ADB: %ADB_EXE%
echo If adb is not on PATH, run: set ADB_PATH=C:\path\to\adb.exe

"%ADB_EXE%" shell am start -W -a android.intent.action.VIEW -d "collectiq-sit://auth/callback?type=signup"
if errorlevel 1 (
  echo Deep link test failed. Confirm CollectIQ SIT is installed and ADB can see the device.
  exit /b 1
)

echo Deep link intent sent. CollectIQ SIT should open and show email confirmation feedback.
endlocal
