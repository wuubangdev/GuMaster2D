@echo off
setlocal
set "PROJECT_ROOT=%~dp0"
set "ENGINE=%PROJECT_ROOT%.tools\godot\Godot_v4.7.2-stable_win64.exe"
if exist "%ENGINE%" (
  if not exist "%PROJECT_ROOT%.godot\global_script_class_cache.cfg" (
    "%PROJECT_ROOT%.tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "%PROJECT_ROOT%." --import
    if errorlevel 1 exit /b 1
  )
  start "GuMaster2D" "%ENGINE%" --path "%PROJECT_ROOT%."
  exit /b 0
)
where godot >nul 2>nul
if not errorlevel 1 (
  start "GuMaster2D" godot --path "%PROJECT_ROOT%."
  exit /b 0
)
echo Open project.godot in Godot 4.7.2 and press F6 or F5.
echo Download: https://godotengine.org/download/windows/
pause
