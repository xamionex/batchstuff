@echo off && title Koalageddon Toggler || 2/21/2024 || 11:20 AM
setlocal enableextensions enabledelayedexpansion
if "%*" equ "1" set aftertoggle=1
if "%*" equ "disable" set disable=1
if "%*" equ "enable" set enable=1

:start
    ::# Steam location setup
    for /f "tokens=2*" %%R in ('reg query HKCU\SOFTWARE\Valve\Steam /v SteamPath 2^>nul') do for %%A in ("%%~S") do set "STEAM=%%~fA"

    ::# elevate with native shell by AveYo
    >nul reg add hkcu\software\classes\.Admin\shell\runas\command /f /ve /d "cmd /x /d /r set \"f0=%%2\"& call \"%%2\" %%3"& set _= %*
    >nul fltmc|| if "%f0%" neq "%~f0" (cd.>"%temp%\runas.Admin" && start "%~n0" /high "%temp%\runas.Admin" "%~f0" "%_:"=""%" && exit /b)

    ::# lean xp+ color macros by AveYo:  %<%:af " hello "%>>%  &&  %<%:cf " w\"or\"ld "%>%   for single \ / " use .%|%\  .%|%/  \"%|%\"
    for /f "delims=:" %%s in ('echo;prompt $h$s$h:^|cmd /d') do set "|=%%s"&set ">>=\..\c nul&set /p s=%%s%%s%%s%%s%%s%%s%%s<nul&popd"
    set "<=pushd "%appdata%"&2>nul findstr /c:\ /a" &set ">=%>>%&echo;" &set "|=%|:~0,1%" &set /p s=\<nul>"%appdata%\c"
    call :check
    if not exist "%STEAM%\version.dll" if "%aftertoggle%" neq "" call :check
    exit

:check
    tasklist /fi "imagename eq Steam.exe" | findstr /i Steam.exe >nul && taskkill /f /im Steam.exe /t
    if "%enable%" equ "1" (
        ren "%STEAM%\disabled_version.dll" "version.dll"
        exit
    )
    if "%disable%" equ "1" (
        ren "%STEAM%\version.dll" "disabled_version.dll"
        exit
    )
    if exist "%STEAM%\version.dll" (
        call :disable
    ) else (
        call :enable
    )
    exit /b


:enable
    ren "%STEAM%\disabled_version.dll" "version.dll"
    %<%:f0 " Koalageddon "%>>% && %<%:2f " ENABLED "%>>% && %<%:f0 " - Run again to disable "%>%
    set /a countdown=5
    call :countdown
    exit /b

:disable
    ren "%STEAM%\version.dll" "disabled_version.dll"
    %<%:f0 " Koalageddon "%>>% && %<%:df " DISABLED "%>>% && %<%:f0 " - Run again to enable "%>%
    %<%:f0 " Console paused, to remind you to enable it later. (Press any key thrice to exit)"%>%
    pause>nul
    pause>nul
    pause>nul
    exit /b

:countdown
    if "%countdown%" equ "0" (
        powershell %string:~1%
        exit /b
    )
    set string=%string%;Write-Host "`rAutomatically exiting in `0" -NoNewline -b White -f Black;Write-Host "%countdown%s" -nonewline -b DarkRed -f White;sleep 1
    set /a countdown=%countdown%-1
    call :countdown