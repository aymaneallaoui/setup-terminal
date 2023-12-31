@echo off

if not exist "%USERPROFILE%\Documents\WindowsPowerShell\" (
  mkdir "%USERPROFILE%\Documents\WindowsPowerShell\"
)

REM Set the path to the PowerShell profile file
set "ProfilePath=%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"


if not exist "%ProfilePath%" type nul > "%ProfilePath%"


findstr /m "oh-my-posh init pwsh" "%ProfilePath%" > nul
if %errorlevel% neq 0 (
  REM Add the configuration to the PowerShell profile if not already present
  (
    
    echo oh-my-posh init pwsh --config '%USERPROFILE%\AppData\Local\Programs\oh-my-posh\themes\montys.omp.json' ^| Invoke-Expression
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
