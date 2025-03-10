# iwr weget.krwclassic.com | iex 

# Simple script that will install weget as system or user (depending on permissions) and add it to path.
# My website is redirecting traffic to github, so script is synced no matter what.

# Add a function to calculate the hash of a file
function Get-FileHashValue {
    param (
        [string]$filePath
    )
    return (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
}

# Script version
$scriptVersion = "v1.5.1"
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
    $installPath = $existingPaths[0]  # Use the first found path
    
    # Check if already in PATH
    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Process)
    if ($currentPath -notlike "*$installPath*") {
        Write-Host "Adding $installPath to PATH" -ForegroundColor Green
        [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$installPath", [System.EnvironmentVariableTarget]::Process)
    } else {
        Write-Host "Already in PATH" -ForegroundColor Yellow
    }
    
    # Verify installation and check hash
    Write-Host "Verifying existing installation..." -ForegroundColor Cyan
    try {
        # Ensure the path to weget.exe is valid
        $wegetExePath = Join-Path $installPath "weget.exe"
        if (-Not (Test-Path $wegetExePath)) {
            Write-Host "weget.exe not found at $wegetExePath" -ForegroundColor Red
            exit 1
        }

        Write-Host "Executing: weget --version" -ForegroundColor Magenta
        $version = & $wegetExePath --version 2>&1  # Use call operator to execute
        if ($LASTEXITCODE -eq 0) {
            # Calculate hash of existing binary
            $existingHash = Get-FileHashValue $wegetExePath
            
            # Fetch the latest binary URL and calculate its hash
            $latestUrl = "https://raw.githubusercontent.com/KRWCLASSIC/weget/refs/heads/main/install/latest_release.txt"
            $binaryUrl = Invoke-WebRequest -Uri $latestUrl -UseBasicParsing | Select-Object -ExpandProperty Content
            
            # Download the new binary to a temporary location
            $tempExeDestination = Join-Path $installPath "weget_temp.exe"
            Invoke-WebRequest -Uri $binaryUrl -OutFile $tempExeDestination -ErrorAction Stop
            
            # Calculate hash of the downloaded binary
            $newHash = Get-FileHashValue $tempExeDestination
            
            # Compare hashes
            if ($existingHash -ne $newHash) {
                Write-Host "New version detected. Updating weget..." -ForegroundColor Green
                Move-Item -Path $tempExeDestination -Destination $wegetExePath -Force
            } else {
                Write-Host "Existing installation is up to date." -ForegroundColor Green
                Remove-Item $tempExeDestination -Force
                exit 0
            }
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

# Refresh PATH in current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Final message
Write-Host "Installation complete! weget is ready to use." -ForegroundColor Green

# Keep window open
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
