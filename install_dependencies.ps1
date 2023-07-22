$script = @"
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Install-Module -Name PSReadLine -AllowClobber -Force
Install-Module -Name Terminal-Icons -Repository PSGallery -Force
Install-Module -Name Posh-Git -Repository PSGallery -Force
Install-Module -Name TabExpansionPlusPlus -Repository PSGallery -Force -AllowClobber
Install-Module -Name PSFzf -Scope CurrentUser -Force
oh-my-posh init pwsh --config '%USERPROFILE%\AppData\Local\Programs\oh-my-posh\themes\montys.omp.json' | Invoke-Expression
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -PredictionSource History
"@

# Run the script as administrator
Start-Process powershell -Verb RunAs -ArgumentList ("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $script)
