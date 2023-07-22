REM Install Oh My Posh using winget
winget install JanDeDobbeleer.OhMyPosh -s winget

REM Install PSReadLine module
Install-Module -Name PSReadLine -AllowClobber -Force

REM Set Execution Policy to RemoteSigned for the CurrentUser
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser 

REM Install Terminal-Icons module from PSGallery repository
Install-Module -Name Terminal-Icons -Repository PSGallery -Force

REM Install Posh-Git module from PSGallery repository
Install-Module -Name Posh-Git -Repository PSGallery -Force

REM install TabExpansionPlusPlus module from PSGallery repository

Install-Module -Name TabExpansionPlusPlus -Repository PSGallery -Force

REM Install Scoop package manager
iwr -useb get.scoop.sh | iex

REM Install PSFzf module for fuzzy searching
Install-Module -Name PSFzf -Scope CurrentUser -Force

REM Initialize Oh My Posh with the desired theme config
oh-my-posh init pwsh --config '%USERPROFILE%\AppData\Local\Programs\oh-my-posh\themes\montys.omp.json' | Invoke-Expression

REM Import PSFzf module
Import-Module PSFzf

REM Configure PSFzf and PSReadLine options
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -PredictionSource History

REM Import Terminal-Icons module
Import-Module Terminal-Icons
