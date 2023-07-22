$downloadUrl = "https://github.com/junegunn/fzf/releases/download/0.42.0/fzf-0.42.0-windows_amd64.zip"
$downloadFolder = "$env:TEMP\fzf_download"

# Function to download and extract fzf
function InstallFzf {
    # Create the download folder if it doesn't exist
    if (-not (Test-Path -Path $downloadFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $downloadFolder | Out-Null
    }

    # Download the fzf zip file
    $zipFile = "$downloadFolder\fzf.zip"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile

    # Extract the contents of the zip file
    Expand-Archive -Path $zipFile -DestinationPath $downloadFolder

    # Get the extracted folder path
    $extractedFolder = Get-ChildItem -Path $downloadFolder -Filter "fzf.exe" -Recurse | Select-Object -ExpandProperty Directory

    # Add the fzf folder to the system's PATH
    $existingPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if (-not ($existingPath -split ';' | Where-Object { $_ -eq $extractedFolder })) {
        [Environment]::SetEnvironmentVariable("Path", "$existingPath;$extractedFolder", "Machine")
    }

    Write-Host "fzf has been successfully installed and added to the system's PATH."
}

# Call the function to install fzf
InstallFzf

# Check if the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script with administrative privileges..."
    Start-Sleep -Seconds 3
    Start-Process powershell -Verb RunAs -ArgumentList "-File $($MyInvocation.MyCommand.Path)"
    Exit
}


Write-Host "Script completed successfully."
