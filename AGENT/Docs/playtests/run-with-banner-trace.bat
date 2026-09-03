@echo off
REM Launch Project Prometheus with the phase-banner trace turned on.
REM
REM v0.7.16 Section 2 asks for one measurement that no automated environment can
REM produce: what the phase banner is doing during a resumed load on a real
REM Windows machine. The build reads ONE environment variable to enable the trace.
REM This file sets it and starts the game, so the tester does not have to use a
REM command prompt. Nothing else about the build changes, and without the variable
REM the tracing code does not run at all.
REM
REM DELIBERATELY BORING. This file cannot be executed in the Linux container that
REM produces the bundle, so it avoids every batch construct that fails quietly --
REM no pipes, no findstr, no parsing. It names the executable it expects, and if
REM that is missing it falls back to a scan and then FAILS LOUDLY. The checklist
REM carries the two manual commands as a third fallback.

setlocal enabledelayedexpansion
set PROMETHEUS_BANNER_TRACE=1

REM The release build, by the exact name this bundle ships. The _debug build is
REM deliberately not preferred: the trace is wanted from the one the round is about.
set "GAME=%~dp0Project_Prometheus_v0.7.16.exe"

if not exist "!GAME!" (
    set "GAME="
    for %%F in ("%~dp0Project_Prometheus_v*.exe") do (
        set "NAME=%%~nF"
        if "!NAME:_debug=!"=="!NAME!" if not defined GAME set "GAME=%%~fF"
    )
)

if not defined GAME (
    echo.
    echo Could not find the game executable beside this file.
    echo Put run-with-banner-trace.bat in the same folder as
    echo   Project_Prometheus_v0.7.16.exe
    echo and run it again. If that keeps failing, Section 2.1 of the checklist
    echo has the two commands to type by hand instead.
    echo.
    pause
    exit /b 1
)

echo Banner trace: ON
echo Launching !GAME!
echo.
echo When you are finished, return the whole logs folder from:
echo   %APPDATA%\Godot\app_userdata\Project Prometheus\logs
echo.
echo Leave this window open while you play.
echo.
"!GAME!"

echo.
echo Game closed. The BANNER_TRACE lines are in the logs folder named above.
pause
endlocal
