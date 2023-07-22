$downloadUrl = "https://objects.githubusercontent.com/github-production-release-asset-2e65be/13807606/4c46be1c-6cbd-4a91-8f91-4d56250ef7e9?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20230722%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20230722T140528Z&X-Amz-Expires=300&X-Amz-Signature=a7333ab0a193e2b41c524d810a7c6cf52ec25487aba845bbdec71f66750c9642&X-Amz-SignedHeaders=host&actor_id=111997551&key_id=0&repo_id=13807606&response-content-disposition=attachment%3B%20filename%3Dfzf-0.42.0-windows_amd64.zip&response-content-type=application%2Foctet-stream"
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
