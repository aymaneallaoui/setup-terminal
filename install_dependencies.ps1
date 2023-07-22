start-process powershell -verb runas

Set-ExecutionPolicy RemoteSigned -Scope CurrentUser



Install-Module -Name PSReadLine -AllowClobber -Force


Set-ExecutionPolicy RemoteSigned -Scope CurrentUser 


Install-Module -Name Terminal-Icons -Repository PSGallery -Force


Install-Module -Name Posh-Git -Repository PSGallery -Force


Install-Module -Name TabExpansionPlusPlus -Repository PSGallery -Force


Install-Module -Name PSFzf -Scope CurrentUser -Force


oh-my-posh init pwsh --config '%USERPROFILE%\AppData\Local\Programs\oh-my-posh\themes\montys.omp.json' | Invoke-Expression




Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -PredictionSource History
