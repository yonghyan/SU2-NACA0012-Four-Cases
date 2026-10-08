# SU2 v8.5.0 quick installer for Windows
# Teaching repository: SU2-NACA0012-Four-Cases
#
# What this script does:
#   1. Downloads the official non-MPI Windows binary for SU2 v8.5.0.
#   2. Extracts it under %USERPROFILE%\SU2\v8.5.0.
#   3. Finds SU2_CFD.exe automatically.
#   4. Sets the user-level SU2_RUN environment variable.
#   5. Adds the SU2 executable directory to the user PATH.
#
# No administrator privileges are required.

$ErrorActionPreference = "Stop"

if ($env:OS -ne "Windows_NT") {
    throw "This installer is intended for Windows only."
}

$Version = "8.5.0"
$ArchiveName = "SU2-v$Version-win64-omp.zip"
$DownloadUrl = "https://github.com/su2code/SU2/releases/download/v$Version/$ArchiveName"

$InstallRoot = Join-Path $env:USERPROFILE "SU2"
$InstallDir = Join-Path $InstallRoot "v$Version"
$ZipPath = Join-Path $env:TEMP $ArchiveName

Write-Host ""
Write-Host "==============================================="
Write-Host " SU2 v$Version Windows quick installer"
Write-Host "==============================================="
Write-Host ""

# GitHub requires modern TLS.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "[1/4] Downloading the official SU2 Windows package..."
Write-Host "      $DownloadUrl"
Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath

Write-Host "[2/4] Extracting SU2 to:"
Write-Host "      $InstallDir"

if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
}
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force

Write-Host "[3/4] Locating SU2_CFD.exe..."
$Su2Exe = Get-ChildItem -Path $InstallDir -Filter "SU2_CFD.exe" -File -Recurse |
    Select-Object -First 1

if (-not $Su2Exe) {
    throw "SU2_CFD.exe was not found after extraction."
}

$Su2Run = $Su2Exe.Directory.FullName

Write-Host "[4/4] Setting SU2_RUN and adding SU2 to the user PATH..."

[Environment]::SetEnvironmentVariable("SU2_RUN", $Su2Run, "User")

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ([string]::IsNullOrWhiteSpace($UserPath)) {
    $PathEntries = @()
} else {
    $PathEntries = $UserPath -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

$AlreadyInPath = $false
foreach ($Entry in $PathEntries) {
    if ($Entry.TrimEnd("\") -ieq $Su2Run.TrimEnd("\")) {
        $AlreadyInPath = $true
        break
    }
}

if (-not $AlreadyInPath) {
    if ([string]::IsNullOrWhiteSpace($UserPath)) {
        $NewUserPath = $Su2Run
    } else {
        $NewUserPath = "$UserPath;$Su2Run"
    }
    [Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")
}

# Also update the current PowerShell process so the executable can be used now.
$env:SU2_RUN = $Su2Run
$CurrentEntries = $env:Path -split ";"
if (-not ($CurrentEntries | Where-Object { $_.TrimEnd("\") -ieq $Su2Run.TrimEnd("\") })) {
    $env:Path = "$Su2Run;$env:Path"
}

Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "SU2 installation completed successfully."
Write-Host ""
Write-Host "SU2_RUN:"
Write-Host "  $Su2Run"
Write-Host ""
Write-Host "SU2_CFD.exe:"
Write-Host "  $($Su2Exe.FullName)"
Write-Host ""
Write-Host "Open a NEW Command Prompt or PowerShell window, then verify with:"
Write-Host "  echo %SU2_RUN%        (Command Prompt)"
Write-Host "  where SU2_CFD         (Command Prompt)"
Write-Host "or"
Write-Host '  $env:SU2_RUN          (PowerShell)'
Write-Host "  Get-Command SU2_CFD   (PowerShell)"
Write-Host ""
Write-Host "Then enter one of the case folders and run, for example:"
Write-Host "  SU2_CFD inv_NACA0012.cfg"
Write-Host ""
