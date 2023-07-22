@echo off

REM Set the path to the PowerShell profile file
set "ProfilePath=%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

REM Create the PowerShell profile file if it doesn't exist
if not exist "%ProfilePath%" type nul > "%ProfilePath%"

REM Check if the configuration commands already exist in the profile file
findstr /m "oh-my-posh init pwsh" "%ProfilePath%" > nul
if %errorlevel% neq 0 (
  REM Add the configuration to the PowerShell profile if not already present
  (
    REM Initialize Oh My Posh with the desired theme config
    echo oh-my-posh init pwsh --config '%USERPROFILE%\AppData\Local\Programs\oh-my-posh\themes\montys.omp.json' | Invoke-Expression
    echo Import-Module Terminal-Icons
    echo Import-Module PSFzf
    echo Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
    echo Set-PSReadLineOption -PredictionViewStyle ListView
  ) >> "%ProfilePath%"
  echo "Configuration has been added to the PowerShell profile."
) else (
  echo "Configuration already exists in the PowerShell profile. No changes made."
)

pause
