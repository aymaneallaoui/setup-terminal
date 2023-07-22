@echo off
setlocal

REM Define the download URL for fzf
set "fzfVersion=0.42.0"
set "fzfZipFileName=fzf-%fzfVersion%-windows_amd64.zip"
set "fzfDownloadURL=https://github.com/junegunn/fzf/releases/download/%fzfVersion%/%fzfZipFileName%"

REM Set the target directory where fzf binary will be placed
set "targetDirectory=C:\Windows\System32"

REM Download the fzf zip file
echo Downloading fzf...
curl -L -o "%fzfZipFileName%" "%fzfDownloadURL%"

REM Unzip the fzf binary from the downloaded zip file
echo Extracting fzf...
powershell -Command "Expand-Archive -Path '%fzfZipFileName%' -DestinationPath '.' -Force"

REM Move the fzf binary to the target directory
echo Moving fzf binary to %targetDirectory%...
move fzf.exe "%targetDirectory%\fzf.exe" > nul

REM Clean up the downloaded zip file
echo Cleaning up...
del "%fzfZipFileName%"

echo fzf has been installed successfully to %targetDirectory%\fzf.exe
pause
