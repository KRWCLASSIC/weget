# iwr weget.krwclassic.com | iex 

# Simple script that will install weget as system or user (depending on permissions) and add it to path.
# My website is redirecting traffic to github, so script is synced no matter what.

# Define installation paths
$userPath = "$env:APPDATA\KRWCLASSIC\weget"
$adminPath = "${env:ProgramFiles}\KRWCLASSIC\weget"
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
} else {
    $installPath = $userPath
}

# Create directory if not exists
if (!(Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
}

# Fetch the latest binary URL
$latestUrl = "https://raw.githubusercontent.com/KRWCLASSIC/weget/refs/heads/main/install/latest_release.txt"
$binaryUrl = Invoke-WebRequest -Uri $latestUrl -UseBasicParsing | Select-Object -ExpandProperty Content

# Download `weget.exe`
$exeDestination = "$installPath\weget.exe"
Invoke-WebRequest -Uri $binaryUrl -OutFile $exeDestination

# Add to PATH
$envPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userEnvPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

if (Test-Admin) {
    if ($envPath -notlike "*$installPath*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$envPath;$installPath", "Machine")
    }
} else {
    if ($userEnvPath -notlike "*$installPath*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$userEnvPath;$installPath", "User")
    }
}

# Verify installation
Start-Process cmd -ArgumentList "/c weget --version & pause" -NoNewWindow -Wait
