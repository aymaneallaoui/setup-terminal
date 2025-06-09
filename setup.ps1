# Universal Terminal Setup Script for PowerShell
# Enhanced by Claude for aymaneallaoui/setup-terminal

# Ensure we can run scripts
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

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

# Function to test if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to install Scoop
function Install-Scoop {
    Write-ColoredOutput "Installing Scoop package manager..." -Type "Step"
    
    if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
        try {
            iex ((New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh'))
            Write-ColoredOutput "Scoop installed successfully" -Type "Success"
        }
        catch {
            Write-ColoredOutput "Failed to install Scoop: $($_.Exception.Message)" -Type "Error"
            return $false
        }
    }
    else {
        Write-ColoredOutput "Scoop is already installed" -Type "Info"
    }
    
    # Add Scoop to PATH for current session
    $env:PATH += ";$env:USERPROFILE\scoop\shims"
    
    return $true
}

# Function to install Winget
function Install-Winget {
    Write-ColoredOutput "Checking for Winget..." -Type "Step"
    
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-ColoredOutput "Installing Winget..." -Type "Info"
        try {
            # Try to install via Microsoft Store
            $wingetPackage = Get-AppxPackage -Name Microsoft.DesktopAppInstaller
            if (!$wingetPackage) {
                Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
            }
            Write-ColoredOutput "Winget installed successfully" -Type "Success"
        }
        catch {
            Write-ColoredOutput "Failed to install Winget. Please install manually from Microsoft Store." -Type "Warning"
            return $false
        }
    }
    else {
        Write-ColoredOutput "Winget is already installed" -Type "Info"
    }
    
    return $true
}

# Function to install Oh My Posh
function Install-OhMyPosh {
    Write-ColoredOutput "Installing Oh My Posh..." -Type "Step"
    
    if (!(Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        try {
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                winget install JanDeLaRepr.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements
            }
            elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
                scoop install oh-my-posh
            }
            else {
                Write-ColoredOutput "Neither Winget nor Scoop available. Installing via PowerShell..." -Type "Info"
                Install-Module oh-my-posh -Scope CurrentUser -Force
            }
            Write-ColoredOutput "Oh My Posh installed successfully" -Type "Success"
        }
        catch {
            Write-ColoredOutput "Failed to install Oh My Posh: $($_.Exception.Message)" -Type "Error"
            return $false
        }
    }
    else {
        Write-ColoredOutput "Oh My Posh is already installed" -Type "Info"
    }
    
    return $true
}

# Function to install PowerShell modules
function Install-PowerShellModules {
    Write-ColoredOutput "Installing PowerShell modules..." -Type "Step"
    
    $modules = @(
        'PSReadLine',
        'Terminal-Icons',
        'Posh-Git',
        'PSFzf'
    )
    
    foreach ($module in $modules) {
        try {
            if (!(Get-Module -ListAvailable -Name $module)) {
                Write-ColoredOutput "Installing $module..." -Type "Info"
                Install-Module -Name $module -Repository PSGallery -Force -AllowClobber -Scope CurrentUser
                Write-ColoredOutput "$module installed successfully" -Type "Success"
            }
            else {
                Write-ColoredOutput "$module is already installed" -Type "Info"
            }
        }
        catch {
            Write-ColoredOutput "Failed to install $module : $($_.Exception.Message)" -Type "Error"
        }
    }
}

# Function to install fzf
function Install-Fzf {
    Write-ColoredOutput "Installing fzf..." -Type "Step"
    
    if (!(Get-Command fzf -ErrorAction SilentlyContinue)) {
        try {
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                scoop install fzf
                Write-ColoredOutput "fzf installed via Scoop" -Type "Success"
            }
            elseif (Get-Command winget -ErrorAction SilentlyContinue) {
                winget install junegunn.fzf
                Write-ColoredOutput "fzf installed via Winget" -Type "Success"
            }
            else {
                Write-ColoredOutput "Neither Scoop nor Winget available for fzf installation" -Type "Warning"
                return $false
            }
        }
        catch {
            Write-ColoredOutput "Failed to install fzf: $($_.Exception.Message)" -Type "Error"
            return $false
        }
    }
    else {
        Write-ColoredOutput "fzf is already installed" -Type "Info"
    }
    
    return $true
}

# Function to create PowerShell profile
function Set-PowerShellProfile {
    Write-ColoredOutput "Configuring PowerShell profile..." -Type "Step"
    
    # Create profile directory if it doesn't exist
    $profileDir = Split-Path $PROFILE -Parent
    if (!(Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    # Backup existing profile
    if (Test-Path $PROFILE) {
        $backupPath = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $PROFILE $backupPath
        Write-ColoredOutput "Existing profile backed up to $backupPath" -Type "Info"
    }
    
    # Create new profile content
    $profileContent = @'
# PowerShell Profile Configuration - Universal Terminal Setup

# Import modules (with error handling)
$modules = @('PSReadLine', 'Terminal-Icons', 'Posh-Git', 'PSFzf')
foreach ($module in $modules) {
    try {
        Import-Module $module -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "Failed to import module: $module"
    }
}

# PSReadLine configuration
if (Get-Module PSReadLine) {
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardWord
    
    # History search with fzf if available
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        Set-PSReadLineKeyHandler -Key "Ctrl+r" -ScriptBlock {
            $line = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
            $selection = Get-Content (Get-PSReadLineOption).HistorySavePath | fzf --tac
            if ($selection) {
                [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
            }
        }
    }
}

# PSFzf configuration
if (Get-Module PSFzf) {
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# Oh My Posh initialization
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $themePath = "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes\montys.omp.json"
    if (Test-Path $themePath) {
        oh-my-posh init pwsh --config $themePath | Invoke-Expression
    } else {
        # Fallback to a built-in theme
        oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression
    }
}

# Aliases
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name l -Value Get-ChildItem
function la { Get-ChildItem -Force @args }
function lla { Get-ChildItem -Force -Format Wide @args }

# Git aliases
function gs { git status @args }
function ga { git add @args }
function gc { git commit @args }
function gp { git push @args }
function gl { git log --oneline @args }
function gd { git diff @args }
function gb { git branch @args }
function gco { git checkout @args }
function gpl { git pull @args }
function gst { git stash @args }

# Useful utility functions
function which($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function grep($regex, $dir) {
    if ($dir) {
        Get-ChildItem $dir | Select-String $regex
        return
    }
    $input | Select-String $regex
}

function touch($file) { 
    if (Test-Path $file) {
        (Get-Item $file).LastWriteTime = Get-Date
    } else {
        "" | Out-File $file -Encoding ASCII 
    }
}

function df {
    Get-Volume | Format-Table -AutoSize
}

function ps1 {
    Get-Process | Where-Object { $_.ProcessName -like "*$args*" }
}

function killall($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function mkcd($dir) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Location $dir
}

# Enhanced cd function with history
function Set-LocationWithHistory {
    param([string]$Path = "~")
    if ($Path -eq "-") {
        if ($global:PreviousLocation) {
            $temp = Get-Location
            Set-Location $global:PreviousLocation
            $global:PreviousLocation = $temp
        }
    } else {
        $global:PreviousLocation = Get-Location
        Set-Location $Path
    }
}
Set-Alias -Name cd -Value Set-LocationWithHistory -Option AllScope

# Welcome message
Write-Host "PowerShell Universal Terminal Setup loaded successfully!" -ForegroundColor Green
Write-Host "Features available:" -ForegroundColor Cyan
Write-Host "  • Enhanced command history (Ctrl+R)" -ForegroundColor Gray
Write-Host "  • File finder with fzf (Ctrl+T)" -ForegroundColor Gray
Write-Host "  • Git aliases (gs, ga, gc, gp, gl, gd, gb, gco)" -ForegroundColor Gray
Write-Host "  • Utility functions (which, grep, touch, df, mkcd)" -ForegroundColor Gray
Write-Host "  • Beautiful prompt with git status" -ForegroundColor Gray
'@

    # Write the profile
    $profileContent | Out-File -FilePath $PROFILE -Encoding UTF8 -Force
    Write-ColoredOutput "PowerShell profile configured successfully" -Type "Success"
}

# Function to install Nerd Font
function Install-NerdFont {
    Write-ColoredOutput "Installing Nerd Font for better terminal icons..." -Type "Step"
    
    try {
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            # Add nerd-fonts bucket and install a font
            scoop bucket add nerd-fonts
            scoop install FiraCode-NF
            Write-ColoredOutput "FiraCode Nerd Font installed via Scoop" -Type "Success"
        }
        else {
            Write-ColoredOutput "Scoop not available. Please install a Nerd Font manually for best experience." -Type "Warning"
            Write-ColoredOutput "Visit: https://www.nerdfonts.com/font-downloads" -Type "Info"
        }
    }
    catch {
        Write-ColoredOutput "Failed to install Nerd Font: $($_.Exception.Message)" -Type "Warning"
        Write-ColoredOutput "You can install manually from: https://www.nerdfonts.com/font-downloads" -Type "Info"
    }
}

# Main setup function
function Start-Setup {
    # Header
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    Universal Terminal Setup                   ║" -ForegroundColor Cyan
    Write-Host "║                     PowerShell Edition                        ║" -ForegroundColor Cyan
    Write-Host "║                     Enhanced by Claude                        ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-ColoredOutput "Starting PowerShell terminal setup..." -Type "Info"
    
    # Check if running as admin (optional for some features)
    if (Test-Administrator) {
        Write-ColoredOutput "Running as Administrator - all features will be available" -Type "Info"
    } else {
        Write-ColoredOutput "Running as regular user - some features may be limited" -Type "Warning"
    }
    
    # Install components
    $success = $true
    
    if (!(Install-Scoop)) { $success = $false }
    if (!(Install-Winget)) { $success = $false }
    if (!(Install-OhMyPosh)) { $success = $false }
    Install-PowerShellModules
    if (!(Install-Fzf)) { $success = $false }
    Install-NerdFont
    Set-PowerShellProfile
    
    # Summary
    Write-Host ""
    if ($success) {
        Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                     Setup Complete!                          ║" -ForegroundColor Green
        Write-Host "║                                                               ║" -ForegroundColor Green
        Write-Host "║  Please restart PowerShell to apply all changes.             ║" -ForegroundColor Green
        Write-Host "║                                                               ║" -ForegroundColor Green
        Write-Host "║  Features installed:                                          ║" -ForegroundColor Green
        Write-Host "║  • Enhanced command history (Ctrl+R)                         ║" -ForegroundColor Green
        Write-Host "║  • File finder with fzf (Ctrl+T)                             ║" -ForegroundColor Green
        Write-Host "║  • Git integration and aliases                                ║" -ForegroundColor Green
        Write-Host "║  • Auto-completion and syntax highlighting                    ║" -ForegroundColor Green
        Write-Host "║  • Beautiful prompt with git status                          ║" -ForegroundColor Green
        Write-Host "║  • Terminal icons and enhanced display                       ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    } else {
        Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║                Setup Completed with Warnings                 ║" -ForegroundColor Yellow
        Write-Host "║                                                               ║" -ForegroundColor Yellow
        Write-Host "║  Some components may not have installed correctly.            ║" -ForegroundColor Yellow
        Write-Host "║  Please check the messages above and install manually        ║" -ForegroundColor Yellow
        Write-Host "║  if needed.                                                   ║" -ForegroundColor Yellow
        Write-Host "║                                                               ║" -ForegroundColor Yellow
        Write-Host "║  Restart PowerShell to apply changes.                        ║" -ForegroundColor Yellow
        Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Run the setup
Start-Setup