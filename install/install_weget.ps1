# iwr weget.krwclassic.com | iex 

# Simple script that will install weget as system or user (depending on permissions) and add it to path.
# My website is redirecting traffic to github, so script is synced no matter what.

# Script version
$scriptVersion = "v1.1"
Write-Host "weget installer $scriptVersion" -ForegroundColor Cyan

# Define installation paths
$userPath = Join-Path $env:APPDATA "KRWCLASSIC\weget"
$adminPath = Join-Path ${env:ProgramFiles} "KRWCLASSIC\weget"
$installPath = ""

# Function to check admin privileges
function Test-Admin {
    $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
    return $prp.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Choose install path
if (Test-Admin) {
    $installPath = $adminPath
    Write-Host "Installing weget system-wide to $installPath" -ForegroundColor Cyan
} else {
    $installPath = $userPath
    Write-Host "Installing weget for current user to $installPath" -ForegroundColor Cyan
}

# Check if already installed in any path
$existingPaths = @($userPath, $adminPath) | Where-Object { Test-Path (Join-Path $_ "weget.exe") }
if ($existingPaths) {
    Write-Host "weget is already installed at: $($existingPaths -join ', ')" -ForegroundColor Yellow
    $installPath = $existingPaths[0]
    
    # Check if already in PATH
    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Process)
    if ($currentPath -notlike "*$installPath*") {
        Write-Host "Adding $installPath to PATH" -ForegroundColor Green
        [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$installPath", [System.EnvironmentVariableTarget]::Process)
    } else {
        Write-Host "Already in PATH" -ForegroundColor Yellow
    }
    
    # Verify installation and exit
    Write-Host "Verifying existing installation..." -ForegroundColor Cyan
    try {
        Write-Host "Executing: weget --version" -ForegroundColor Magenta
        $version = weget --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "weget is ready to use" -ForegroundColor Green
            exit 0
        } else {
            Write-Host "Existing installation verification failed" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "Failed to verify existing installation: $_" -ForegroundColor Red
        exit 1
    }
} else {
    # Create directory if not exists
    if (!(Test-Path $installPath)) {
        Write-Host "Creating installation directory: $installPath" -ForegroundColor Green
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    }
}

# Ensure the installation path exists
if (!(Test-Path $installPath)) {
    Write-Host "Failed to create installation directory: $installPath" -ForegroundColor Red
    exit 1
}

# Fetch the latest binary URL
try {
    $latestUrl = "https://raw.githubusercontent.com/KRWCLASSIC/weget/refs/heads/main/install/latest_release.txt"
    $binaryUrl = Invoke-WebRequest -Uri $latestUrl -UseBasicParsing | Select-Object -ExpandProperty Content
    
    # Validate binary URL
    if ([string]::IsNullOrEmpty($binaryUrl)) {
        Write-Host "Failed to get binary URL" -ForegroundColor Red
        exit 1
    }
    
    # Download `weget.exe`
    $exeDestination = Join-Path $installPath "weget.exe"
    Write-Host "Downloading weget to: $exeDestination" -ForegroundColor Cyan
    
    # Ensure the parent directory exists
    $parentDir = Split-Path $exeDestination -Parent
    if (!(Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    
    Invoke-WebRequest -Uri $binaryUrl -OutFile $exeDestination -ErrorAction Stop
} catch {
    Write-Host "Failed to download weget: $_" -ForegroundColor Red
    exit 1
}

# Add to PATH (with duplicate check)
$envPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userEnvPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

if (Test-Admin) {
    if ($envPath -notlike "*$installPath*") {
        Write-Host "Adding to system PATH" -ForegroundColor Green
        [System.Environment]::SetEnvironmentVariable("Path", "$envPath;$installPath", "Machine")
    } else {
        Write-Host "Already in system PATH" -ForegroundColor Yellow
    }
} else {
    if ($userEnvPath -notlike "*$installPath*") {
        Write-Host "Adding to user PATH" -ForegroundColor Green
        [System.Environment]::SetEnvironmentVariable("Path", "$userEnvPath;$installPath", "User")
    } else {
        Write-Host "Already in user PATH" -ForegroundColor Yellow
    }
}

# Verify installation in background
Write-Host "Verifying installation..." -ForegroundColor Cyan
try {
    # Open new PowerShell window with verification command
    $verifyCommand = "weget --version; if ($LASTEXITCODE -eq 0) { Write-Host 'weget is ready to use' -ForegroundColor Green } else { Write-Host 'Installation verification failed' -ForegroundColor Red }"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $verifyCommand
    
    # Close current window
    Stop-Process -Id $PID
} catch {
    Write-Host "Failed to verify installation: $_" -ForegroundColor Red
    exit 1
}
