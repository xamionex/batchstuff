@echo off
set logging=off
@echo %logging%
setlocal EnableExtensions DisableDelayedExpansion
cd %~dp0
echo.> phone.log
if "%*" EQU "" (call :log "50" "X" "Script started with %0") else (call :log "50" "X" "Script started with %0 %*")

:: Starting case
:: Shamelessly stolen from https://stackoverflow.com/questions/18423443/switch-statement-EQUivalent-in-windows-batch-file
call :case_%* 2>nul

:: Launched with no arguments
call :main

:: Update scrcpy / download for the first time
:case_update_scrcpy
    call :downloadrestart "Genymobile" "scrcpy" "win64"

:: Update VDesk / download for the first time
:case_update_vdesk
    call :downloadrestart "LittleVaaty" "VDesk" "x64"

:: Launched with silent, relaunches with hidden console
:: Also get silent, make it if it doesn't exist
:case_silent
    (start "" "silent.vbs" %~nx0) || call :make_silent
    exit

:: Derived from :case_silent
:make_silent
    (
        echo dim CurrentDirectory
        echo Set objShell = WScript.CreateObject(^"WScript.Shell")
        echo Set fso = CreateObject(^"Scripting.FileSystemObject")
        echo CurrentDirectory = CreateObject(^"Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
        echo objShell.Run ^"cmd /c " & fso.BuildPath(CurrentDirectory, WScript.Arguments(0)), 0, True
    )> silent.vbs
    if "%silentvr%" EQU "true" goto :case_silentvr
    goto :case_silent
    exit /b

:: Launched with kill
:case_kill
    set exit=Kill case was launched
    set force=true
    goto :exit

:: Launched with silentvr
:case_silentvr
    set silentvr=true
    call :case_vr
    call :case_silent
    exit

:: Launched with vr
:case_vr
    call :log "16" "O" "Starting in VR"
    set vdesk=true
    if "%silentvr%" EQU "true" exit /b
    goto :main

:: SCRIPT STARTS HERE
:main
    call :log "16" "-" "Getting Date"
    call :get_date
    call :log "16" "-" "Got Date" "DATE: %ldt%"
    call :log "16" "-" "Getting Config"
    call :config
    call :log "16" "-" "Got Config" "WIFI:%enable% IP:%ip% PORT:%port% | ARGS:%arguments%"
    call :log "16" "?" "Testing scrcpy"
    if "%scrcpyexe%" EQU "" call :case_update_scrcpy
    if not exist "%scrcpyexe%" call :case_update_scrcpy
    if "%vdeskexe%" EQU "" call :case_update_vdesk
    if not exist "%vdeskexe%" call :case_update_vdesk
    call :log "16" "-" "Everything is Working"
    call :log "24" "!" "Starting Up" "DATE: %ldt% | WIFI:%enable% IP:%ip% PORT:%port% | ARGS:%arguments%"
    call :run
    goto :exit

:: Global exit case
:exit
    if "%exit%" EQU "" set exit=Exiting Naturally
    if "%force%" EQU "true" (taskkill /F /IM scrcpy.exe /T && taskkill /F /IM adb.exe /T)>nul 2>nul
    call :log "24" "-" "%exit%"
    call :log "24" "X"
    exit

:: Running scrcpy
:run
    (
    if %enable% EQU true (%scrcpyfolder%adb.exe tcpip %port% && %scrcpyfolder%adb.exe connect %ip%:%port%)
    if "%vdesk%" EQU "true" (%vdeskexe% run -n -o 2 %scrcpyexe% -a "%arguments%") else (%scrcpyexe% %arguments%)
    )>> phone.log
    exit /b

:: Get config, make it if it doesn't exist
:config
    set save=0

    for /f "eol=[ delims=" %%a in (phone.cfg) do set "%%a"
    if "%enable%" EQU "" (set save=1) && (set enable=false)
    if "%ip%" EQU "" (set save=1) && (set ip=192.168.X.X)
    if "%port%" EQU "" (set save=1) && (set port=5555)
    if "%scrcpyexe%" EQU "" (
        set save=1
        pushd .
        for /f "tokens=* delims=" %%a in ('dir /S /B scrcpy.exe') do set "scrcpyexe=%%a"
        if "%downloading%" EQU "" (if "%scrcpyexe%" EQU "" (call :case_update_scrcpy))
    )
    if "%scrcpyfolder%" EQU "" (
        set save=1
        set scrcpyfolder=%scrcpyexe:scrcpy.exe=%
    )
    if "%vdeskexe%" EQU "" (
        set save=1
        pushd .
        for /f "tokens=* delims=" %%a in ('dir /S /B VDesk.exe') do set "vdeskexe=%%a"
        if "%downloading%" EQU "" (if "%vdeskexe%" EQU "" (call :case_update_vdesk))
    )
    if "%arguments%" EQU "" (set save=1) && (set "arguments=-f -Sw -b 10M --video-codec=h265")
    if %save% EQU 1 call :update_config

    :: Checks for infinite loops, in case of one, ask user if to reset config
    set /a loop=loop+1
    if %loop% GEQ 5 (
        call :log "50" "X" "Something is wrong with the config, asking user"
        call :YesNoBox "Something is wrong with the config, Do you want to reset it?"
        if "%YesNo%" EQU "7" (call :MessageBox "Exiting" "Goodbye") && (exit)
        if "%YesNo%" EQU "6" (
            set /a loop=0
            call :reset_config
            call :MessageBox "Reset" "The config has been reset"
        )
    )

    exit /b

    :: was gonna be used but it creates more problems than solving them
    for %%a in (enable ip port arguments) do call :test_var %%a

:test_var
    set var=%*
    for /f "tokens=*" %%a in ('echo "%%%*%%"') do call :subtest %%a
    exit /b

:subtest
    if %* EQU "" call :log "50" "X" "Something is wrong with the config, exiting" && call :MessageBox "Something is wrong with the config, exiting" && exit
    exit /b

:: Derived from :config
:update_config
    (
        echo [Enable Wireless ADB]
        echo enable=%enable%
        echo [Connection Config]
        echo ip=%ip%
        echo port=%port%
        echo [VDesk Path]
        echo vdeskexe=%vdeskexe%
        echo [Scrcpy Path]
        echo scrcpyfolder=%scrcpyfolder%
        echo scrcpyexe=%scrcpyexe%
        echo [Scrcpy Arguments]
        echo arguments=%arguments%
    )> phone.cfg
    set save=0
    goto :config
    exit /b

:: Derived from :config
:reset_config
    (
        echo [Enable Wireless ADB]
        echo enable=
        echo [Connection Config]
        echo ip=
        echo port=
        echo [Scrcpy Path]
        echo scrcpyexe=
        echo [Scrcpy Arguments]
        echo arguments=
    )> phone.cfg
    goto :config
    exit /b

:: Get current date for use in logs
:get_date
    for /f "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
    set ldt=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2% %ldt:~8,2%:%ldt:~10,2%:%ldt:~12,6%
    exit /b

:: Logs from main and such
:log
    @echo off
    if ["%~3"] EQU [""] (set msg=%~2) else (set msg= %~3 )
    set chars=0
    call :stringchars "%msg%"
    set /a dashloops=%~1-(chars/2)
    if not "%dashloops:-=%" EQU "%dashloops%" set dashloops=%dashloops:-=% && echo "The below log call is too long! The dashloop result is negative. We circumvented it, please increase the radius: %~1">> phone.log
    set dashsymbol=%~2
    set dashloop=0
    set dashes=
    call :dashloop
    set finalmsg=%dashes%%msg%%dashes%
    set dash=
    for /f "delims=" %%a in ('cmd /Q /U /C echo %finalmsg%^| find /V ""') do call :adddash
    (
        echo %finalmsg%
        if not "%~4" EQU "" (
            for %%a in ("%~4") do echo %%a
            echo %dash%
        )
    )>> phone.log
    @echo %logging%
    exit /b

:: Adds dashes to %dashes% for :log
:dashloop
    if not %dashloop% EQU %dashloops% (set dashes=%dashes%%dashsymbol%) && set /a dashloop=dashloop+1 && goto :dashloop
    exit /b

:: Adds dashes to %dash% for :log
:adddash
    set dash=%dash%%dashsymbol%
    exit /b

:: Calc how many chars in a string
:stringchars
    for /f "delims=" %%a in ('cmd /Q /U /C echo %~1^| find /V ""') do set /a chars=chars+1
    exit /b

:: Some code stolen from https://gist.github.com/Splaxi/fe168eaa91eb8fb8d62eba21736dc88a
:: Some code stolen from https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8
:: Some from https://stackoverflow.com/questions/23618016/use-powershell-variable-in-batch
:downloadrestart
    set author=%~1
    set program=%~2
    set filenamePattern=%~3
    set download=https://api.github.com/repos/%author%/%program%/releases
    set downloading=true
    call :YesNoBox "Do you want to install %program% in the local directory?"
    if "%YesNo%" EQU "7" (call :MessageBox "Exiting" "Goodbye" && exit)
    call :MessageBox "Program will relaunch automatically, please wait." "Downloading"
    call :log "16" "?" "Fetching latest %program%"
    for /f "tokens=1,* delims=:" %%a in ('curl -s %download% ^| findstr "browser_download_url" ^| findstr "%filenamePattern%"') do (
        call :releaselist %%b
    )
    for /f "tokens=1 delims= " %%a in ('echo %latestlist%') do set latest=%%a
    call :log "24" "-" "Found Latest %program%" "%latest%"
    curl -kOL "%latest%"
    for %%i in ("%latest:/=\%") do (set filename=%%~ni) && (set ext=%%~xi)
    powershell -Command "Expand-Archive -force %filename%%ext% -DestinationPath .; Remove-Item -force %filename%%ext%; Start-Process ./phone.bat"
    call :config
    exit

:releaselist
    set latest=%~1
    set latest=%latest: =%
    set latest=%latest:"=%
    set latestlist=%latestlist% %latest%
    exit /b

:: Yes no taken from https://superuser.com/questions/916284/how-to-show-a-comfirmation-dialog-when-a-batch-file-window-is-closed
:: Usage example in :downloadrestart
:YesNoBox
    :: returns 6 = Yes, 7 = No. Type=4 = Yes/No
    set YesNo=
    set MsgType=4
    set heading=%~2
    set message=%~1
    echo wscript.echo msgbox(WScript.Arguments(0),%MsgType%,WScript.Arguments(1)) >"%temp%\input.vbs"
    for /f "tokens=* delims=" %%a in ('cscript //nologo "%temp%\input.vbs" "%message%" "%heading%"') do set YesNo=%%a
    exit /b

:MessageBox
    set heading=%~2
    set message=%~1
    echo msgbox WScript.Arguments(0),0,WScript.Arguments(1) >"%temp%\input.vbs"
    cscript //nologo "%temp%\input.vbs" "%message%" "%heading%"
    exit /b
