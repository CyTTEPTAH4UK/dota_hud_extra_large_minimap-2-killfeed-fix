@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo   Extra Large Minimap Fix by KARAM_BO$$
echo ===================================================

                                                  
echo                                ##                
echo                            @@####                
echo                          ##########              
echo                        ############@@            
echo                          ############            
echo                          ##############          
echo                  ######    ############          
echo              ##########    ##############        
echo              ############    ############        
echo              ##############    ############      
echo          ##    ############    ##############    
echo      ######    ##############    ############    
echo    ##########    ############    ##############  
echo  ############    ##############    ############  
echo    ############    ############    ##############

echo.
set /p "CONFIRM=Install extralarge minimap fix? (y/n): "
if /i not "%CONFIRM%"=="y" goto :cancelled

set "TARGET_PATH=panorama/styles/hud/dota_hud_combat_events.vcss_c"
set "SOURCE_FILE=%~dp0dota_hud_combat_events.vcss_c"

set "VPKEDIT="
where vpkeditcli.exe >nul 2>nul
if %errorlevel%==0 set "VPKEDIT=vpkeditcli.exe"
if defined VPKEDIT goto :found_vpkedit

if exist "C:\Program Files\VPKEdit\vpkeditcli.exe" set "VPKEDIT=C:\Program Files\VPKEdit\vpkeditcli.exe"
if defined VPKEDIT goto :found_vpkedit

for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\*vpkedit*") do (
    if exist "%%D\vpkeditcli.exe" set "VPKEDIT=%%D\vpkeditcli.exe"
)
if defined VPKEDIT goto :found_vpkedit

echo VPKEdit not found, installing via winget...
winget install --id craftablescience.VPKEdit -e --accept-source-agreements --accept-package-agreements
if %errorlevel% neq 0 goto :winget_failed

where vpkeditcli.exe >nul 2>nul
if %errorlevel%==0 set "VPKEDIT=vpkeditcli.exe"
if defined VPKEDIT goto :found_vpkedit

if exist "C:\Program Files\VPKEdit\vpkeditcli.exe" set "VPKEDIT=C:\Program Files\VPKEdit\vpkeditcli.exe"
if defined VPKEDIT goto :found_vpkedit

for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\*vpkedit*") do (
    if exist "%%D\vpkeditcli.exe" set "VPKEDIT=%%D\vpkeditcli.exe"
)
if not defined VPKEDIT goto :vpkedit_not_found
goto :found_vpkedit

:found_vpkedit
echo Using VPKEdit: %VPKEDIT%
echo.

set "FOUND_COUNT=0"

for %%L in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    call :check_path "%%L:\Program Files (x86)\Steam\steamapps\common\dota 2 beta"
    call :check_path "%%L:\SteamLibrary\steamapps\common\dota 2 beta"
    call :check_path "%%L:\Steam\steamapps\common\dota 2 beta"
)

if "%FOUND_COUNT%"=="0" goto :ask_manual_path
if "%FOUND_COUNT%"=="1" (
    set "DOTA_PATH=!FOUND_1!"
    echo Found Dota 2: !DOTA_PATH!
    goto :path_set
)

echo Found multiple Dota 2 installations:
for /l %%i in (1,1,%FOUND_COUNT%) do echo   %%i^) !FOUND_%%i!
set /p "CHOICE=Enter the number of the install to use: "
set "DOTA_PATH=!FOUND_%CHOICE%!"
goto :path_set

:ask_manual_path
echo Dota 2 was not found automatically on any drive.
set /p "DOTA_PATH=Enter the path to the 'dota 2 beta' folder manually: "
goto :path_set

:path_set
set "VPK=%DOTA_PATH%\game\dota\pak01_dir.vpk"

if not exist "%VPK%" goto :vpk_not_found

echo Replacing file in the archive...
"%VPKEDIT%" "%VPK%" --remove-file "%TARGET_PATH%" --add-file "%SOURCE_FILE%" "%TARGET_PATH%"

if %errorlevel%==0 goto :success
goto :replace_failed

:check_path
set "P=%~1"
if not exist "%P%\game\dota\pak01_dir.vpk" goto :eof
set /a FOUND_COUNT+=1
set "FOUND_%FOUND_COUNT%=%P%"
goto :eof

:cancelled
echo Installation cancelled.
goto :end

:winget_failed
echo Failed to install via winget.
echo Install VPKEdit manually: https://github.com/craftablescience/VPKEdit/releases
goto :end

:vpkedit_not_found
echo Could not find vpkeditcli.exe even after installation.
goto :end

:vpk_not_found
echo pak01_dir.vpk not found at: %VPK%
goto :end

:replace_failed
echo.
echo Something went wrong while replacing the file (error code %errorlevel%).
goto :end

:success
echo.
echo ===================================
echo   Done! The fix was installed successfully.
echo   Launch Dota 2 and check the killfeed.
echo ===================================

:end
echo.
echo Press any key to close this window...
pause >nul
exit /b 0