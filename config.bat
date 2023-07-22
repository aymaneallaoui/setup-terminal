@echo off

REM Set the path to the PowerShell profile file
set "ProfilePath=%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

REM Check if the configuration commands already exist in the profile file
findstr /m "oh-my-posh init pwsh" "%ProfilePath%" > nul
if %errorlevel% neq 0 (
  REM Add the configuration to the PowerShell profile if not already present
  (
    echo "oh-my-posh init pwsh --config 'C:\Users\aymane\AppData\Local\Programs\oh-my-posh\themes\montys.omp.json' | Invoke-Expression"
    echo "Import-Module Terminal-Icons"
    echo "Import-Module PSFzf"
    echo "Import-Module -Name Posh-Git"
    echo "Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'"
    echo "Import-Module -Name TabExpansionPlusPlus"
    echo "Set-PSReadLineOption -PredictionViewStyle ListView"
  ) >> "%ProfilePath%"
  echo "Configuration has been added to the PowerShell profile."
) else (
  echo "Configuration already exists in the PowerShell profile. No changes made."
)

pause
