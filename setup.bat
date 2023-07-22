REM Install Oh My Posh using winget
winget install JanDeDobbeleer.OhMyPosh -s winget

REM Install Scoop package manager
iwr -useb get.scoop.sh | iex

REM Run the PowerShell script to install PowerShell modules and configure Oh My Posh
powershell.exe -ExecutionPolicy Bypass -File "install_dependencies.ps1"
