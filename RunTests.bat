@echo off
setlocal
set "PROJECT_ROOT=%~dp0"
set "ENGINE=%PROJECT_ROOT%.tools\godot\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%ENGINE%" (
  echo Godot portable missing. Import project.godot in Godot 4.7.2 first.
  pause
  exit /b 1
)
"%ENGINE%" --headless --path "%PROJECT_ROOT%." --import
if errorlevel 1 exit /b 1
"%ENGINE%" --headless --path "%PROJECT_ROOT%." --script res://tests/test_runner.gd -- --test-mode
set "TEST_EXIT=%ERRORLEVEL%"
pause
exit /b %TEST_EXIT%
