@echo off

REM Check if the script is running with administrative privileges
NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges. Please run as an administrator.
    pause
    exit /b 1
)

setlocal

REM Set the URL for the latest fzf release
set "fzf_release_url=https://github.com/junegunn/fzf/releases/latest"

REM Set the target installation directory for fzf binary (change as needed)
set "installation_directory=C:\Windows\System32"

REM Download the latest fzf release using curl (you can replace with other download tools)
echo Downloading fzf binary...
curl -sSL -o fzf.zip %fzf_release_url%

REM Unzip the downloaded archive
echo Extracting fzf binary...
powershell -command "Expand-Archive -Path .\fzf.zip -DestinationPath .\fzf"

REM Move the fzf binary to the installation directory
echo Moving fzf binary to %installation_directory%...
move /y .\fzf\fzf.exe "%installation_directory%"

REM Clean up temporary files
echo Cleaning up...
rmdir /s /q .\fzf
del fzf.zip

REM Add the installation directory to the PATH environment variable
echo Updating PATH...
setx PATH "%installation_directory%;%PATH%" /M

echo Installation completed successfully!

pause
