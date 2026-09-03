@echo off
REM Launch Project Prometheus with the phase-banner trace turned on.
REM
REM v0.7.16 Section 2 asks for one measurement that no automated environment can
REM produce: what the phase banner is doing during a resumed load on a real
REM Windows machine. The build carries the instrumentation and reads ONE
REM environment variable to enable it. This file sets that variable and starts the
REM game, so the tester does not have to use a command prompt.
REM
REM Nothing else about the build changes. Without the variable the tracing code
REM does not run at all.

setlocal
set PROMETHEUS_BANNER_TRACE=1

REM Prefer the release executable; the bundle also ships a _debug build and the
REM trace is wanted from the one the round is actually about.
set "GAME="
for %%F in ("%~dp0Project_Prometheus_v*.exe") do (
    echo %%~nxF | findstr /I "debug" >nul || set "GAME=%%~fF"
)

if not defined GAME (
    echo Could not find Project_Prometheus_v*.exe beside this file.
    echo Put this .bat in the same folder as the game executable and run it again.
    pause
    exit /b 1
)

echo Banner trace: ON
echo Launching %GAME%
echo.
echo When you are done, return the whole logs folder from
echo   %%APPDATA%%\Godot\app_userdata\Project Prometheus\logs
echo.
"%GAME%"
endlocal
