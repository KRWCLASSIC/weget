# Script version
$scriptVersion = "v1.6"
Write-Host "weget installer $scriptVersion" -ForegroundColor Cyan

# Define installation paths
$userPath = Join-Path $env:APPDATA "KRWCLASSIC\weget"
$adminPath = Join-Path ${env:ProgramFiles} "KRWCLASSIC\weget"
$installPath = ""

# Add a function to calculate the hash of a file
function Get-FileHashValue {
    param ([string]$filePath)
    return (Get-FileHash -Path $filePath -Algorithm SHA256).Hash
}

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

# Ensure the installation path is set
if ([string]::IsNullOrEmpty($installPath)) {
    Write-Host "Error: Install path is empty!" -ForegroundColor Red
    exit 1
}

# Check if already installed in any path
$existingPaths = @($userPath, $adminPath) | Where-Object { Test-Path (Join-Path $_ "weget.exe") }
if ($existingPaths) {
    Write-Host "weget is already installed at: $($existingPaths -join ', ')" -ForegroundColor Yellow
    $installPath = $existingPaths
} else {
    # Create directory if it does not exist
    if (!(Test-Path $installPath)) {
        Write-Host "Creating installation directory: $installPath" -ForegroundColor Green
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    }
}

# Verify installation
$wegetExePath = Join-Path $installPath "weget.exe"
Write-Host "Expected weget.exe path: $wegetExePath" -ForegroundColor Magenta
if (Test-Path $wegetExePath) {
    Write-Host "Verifying existing installation..." -ForegroundColor Cyan
}

# Verify existing installation
if (Test-Path $wegetExePath) {
    try {
        $existingHash = Get-FileHashValue $wegetExePath
        $latestUrl = "https://raw.githubusercontent.com/KRWCLASSIC/weget/refs/heads/main/install/latest_release.txt"
        $binaryUrl = Invoke-WebRequest -Uri $latestUrl -UseBasicParsing | Select-Object -ExpandProperty Content
        $tempExeDestination = Join-Path $installPath "weget_temp.exe"
        Invoke-WebRequest -Uri $binaryUrl -OutFile $tempExeDestination -ErrorAction Stop
        $newHash = Get-FileHashValue $tempExeDestination
        if ($existingHash -ne $newHash) {
            Write-Host "New version detected. Updating weget..." -ForegroundColor Green
            Move-Item -Path $tempExeDestination -Destination $wegetExePath -Force
        } else {
            Write-Host "Existing installation is up to date." -ForegroundColor Green
            Remove-Item $tempExeDestination -Force
            exit 0
        }
    } catch {
        Write-Host "Failed to verify existing installation: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "weget.exe not found. Proceeding with installation..." -ForegroundColor Yellow
}

# Fetch the latest binary URL and install
try {
    $latestUrl = "https://raw.githubusercontent.com/KRWCLASSIC/weget/refs/heads/main/install/latest_release.txt"
    $binaryUrl = Invoke-WebRequest -Uri $latestUrl -UseBasicParsing | Select-Object -ExpandProperty Content
    if ([string]::IsNullOrEmpty($binaryUrl)) {
        Write-Host "Failed to get binary URL" -ForegroundColor Red
        exit 1
    }
    $exeDestination = Join-Path $installPath "weget.exe"
    Write-Host "Downloading weget to: $exeDestination" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $binaryUrl -OutFile $exeDestination -ErrorAction Stop
} catch {
    Write-Host "Failed to download weget: $_" -ForegroundColor Red
    exit 1
}

# Add to PATH
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
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
