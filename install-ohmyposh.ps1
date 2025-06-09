# Oh My Posh Manual Installation Script
# For cases where the main setup script doesn't install Oh My Posh

Write-Host "=== Oh My Posh Manual Installation ===" -ForegroundColor Cyan
Write-Host ""

# Function to write colored output
function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    switch ($Type) {
        "Info"    { Write-Host "[INFO] $Message" -ForegroundColor Blue }
        "Success" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        "Warning" { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        "Error"   { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "Step"    { Write-Host "[STEP] $Message" -ForegroundColor Magenta }
    }
}

# Check if Oh My Posh is already installed
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-ColoredOutput "Oh My Posh is already installed!" -Type "Success"
    $version = oh-my-posh --version
    Write-ColoredOutput "Version: $version" -Type "Info"
    exit 0
}

Write-ColoredOutput "Oh My Posh not found. Attempting installation..." -Type "Step"

# Method 1: Try Winget (most reliable)
Write-ColoredOutput "Method 1: Trying Winget installation..." -Type "Step"
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try {
        Write-ColoredOutput "Installing Oh My Posh via Winget..." -Type "Info"
        winget install JanDeLaRepr.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements
        
        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
            Write-ColoredOutput "Oh My Posh installed successfully via Winget!" -Type "Success"
            exit 0
        }
    }
    catch {
        Write-ColoredOutput "Winget installation failed: $($_.Exception.Message)" -Type "Warning"
    }
} else {
    Write-ColoredOutput "Winget not available" -Type "Warning"
}

# Method 2: Try Scoop
Write-ColoredOutput "Method 2: Trying Scoop installation..." -Type "Step"
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    try {
        Write-ColoredOutput "Installing Oh My Posh via Scoop..." -Type "Info"
        scoop install oh-my-posh
        
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
            Write-ColoredOutput "Oh My Posh installed successfully via Scoop!" -Type "Success"
            exit 0
        }
    }
    catch {
        Write-ColoredOutput "Scoop installation failed: $($_.Exception.Message)" -Type "Warning"
    }
} else {
    Write-ColoredOutput "Scoop not available" -Type "Warning"
}

# Method 3: Try PowerShell Gallery
Write-ColoredOutput "Method 3: Trying PowerShell Gallery..." -Type "Step"
try {
    Write-ColoredOutput "Installing Oh My Posh from PowerShell Gallery..." -Type "Info"
    Install-Module oh-my-posh -Scope CurrentUser -Force -AllowClobber
    
    if (Get-Module -ListAvailable -Name oh-my-posh) {
        Write-ColoredOutput "Oh My Posh module installed successfully!" -Type "Success"
        Write-ColoredOutput "Note: You may need to restart PowerShell for the command to be available." -Type "Info"
        exit 0
    }
}
catch {
    Write-ColoredOutput "PowerShell Gallery installation failed: $($_.Exception.Message)" -Type "Warning"
}

# Method 4: Manual download (last resort)
Write-ColoredOutput "Method 4: Trying manual download..." -Type "Step"
try {
    Write-ColoredOutput "Downloading Oh My Posh manually..." -Type "Info"
    
    # Create directory
    $ohMyPoshDir = "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh"
    if (!(Test-Path $ohMyPoshDir)) {
        New-Item -ItemType Directory -Path $ohMyPoshDir -Force | Out-Null
    }
    
    # Download the latest release
    $downloadUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe"
    $destinationPath = "$ohMyPoshDir\oh-my-posh.exe"
    
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath
    
    # Add to PATH for current session
    $env:PATH += ";$ohMyPoshDir"
    
    # Add to user PATH permanently
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$ohMyPoshDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$ohMyPoshDir", "User")
    }
    
    # Test if it works
    if (Test-Path $destinationPath) {
        Write-ColoredOutput "Oh My Posh downloaded successfully!" -Type "Success"
        Write-ColoredOutput "Executable location: $destinationPath" -Type "Info"
        Write-ColoredOutput "Please restart PowerShell to use Oh My Posh" -Type "Warning"
        exit 0
    }
}
catch {
    Write-ColoredOutput "Manual download failed: $($_.Exception.Message)" -Type "Error"
}

# If all methods failed
Write-ColoredOutput "All installation methods failed!" -Type "Error"
Write-Host ""
Write-Host "Manual installation options:" -ForegroundColor Yellow
Write-Host "1. Install from Microsoft Store: ms-windows-store://pdp/?ProductId=XP8K0HKJFRXGCK" -ForegroundColor Gray
Write-Host "2. Download from: https://ohmyposh.dev/docs/installation/windows" -ForegroundColor Gray
Write-Host "3. Use Chocolatey: choco install oh-my-posh" -ForegroundColor Gray
Write-Host ""
Write-Host "After manual installation, restart PowerShell and run:" -ForegroundColor Yellow
Write-Host "oh-my-posh init pwsh | Invoke-Expression" -ForegroundColor Gray