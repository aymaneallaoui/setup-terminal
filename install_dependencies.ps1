start-process powershell -verb runas

Set-ExecutionPolicy RemoteSigned -Scope CurrentUser


# Install PSReadLine module
Install-Module -Name PSReadLine -AllowClobber -Force

# Set Execution Policy to RemoteSigned for the CurrentUser
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser 

# Install Terminal-Icons module from PSGallery repository
Install-Module -Name Terminal-Icons -Repository PSGallery -Force

# Install Posh-Git module from PSGallery repository
Install-Module -Name Posh-Git -Repository PSGallery -Force

# Install TabExpansionPlusPlus module from PSGallery repository
Install-Module -Name TabExpansionPlusPlus -Repository PSGallery -Force

# Install PSFzf module for fuzzy searching
Install-Module -Name PSFzf -Scope CurrentUser -Force

# Initialize Oh My Posh with the desired theme config
oh-my-posh init pwsh --config '%USERPROFILE%\AppData\Local\Programs\oh-my-posh\themes\montys.omp.json' | Invoke-Expression



# Configure PSFzf and PSReadLine options
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -PredictionSource History
