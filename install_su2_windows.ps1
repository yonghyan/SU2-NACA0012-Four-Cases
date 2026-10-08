# Configure SU2 environment variables on Windows
# Teaching repository: SU2-NACA0012-Four-Cases
#
# Before running this script:
#   1. Download the official Windows SU2 package yourself.
#   2. Extract it anywhere inside this teaching repository.
#
# What this script does:
#   1. Searches this repository for SU2_CFD.exe.
#   2. Sets the user-level SU2_RUN environment variable.
#   3. Adds the directory containing SU2_CFD.exe to the user PATH.
#
# This script does NOT download or extract SU2.
# No administrator privileges are required.

$ErrorActionPreference = "Stop"

if ($env:OS -ne "Windows_NT") {
    throw "This script is intended for Windows only."
}

Write-Host ""
Write-Host "==============================================="
Write-Host " SU2 Windows environment setup"
Write-Host "==============================================="
Write-Host ""
Write-Host "Searching this repository for SU2_CFD.exe..."

$Su2Exe = Get-ChildItem -Path $PSScriptRoot -Filter "SU2_CFD.exe" -File -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1

if (-not $Su2Exe) {
    Write-Host ""
    Write-Host "SU2_CFD.exe was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:"
    Write-Host "  1. Download the official Windows SU2 package."
    Write-Host "  2. Extract it somewhere inside this repository."
    Write-Host "     Recommended folder: .\SU2"
    Write-Host "  3. Run install_su2_windows.bat again."
    Write-Host ""
    exit 1
}

$Su2Run = $Su2Exe.Directory.FullName

Write-Host "Found:"
Write-Host "  $($Su2Exe.FullName)"
Write-Host ""
Write-Host "Configuring SU2_RUN and user PATH..."

[Environment]::SetEnvironmentVariable("SU2_RUN", $Su2Run, "User")

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ([string]::IsNullOrWhiteSpace($UserPath)) {
    $PathEntries = @()
} else {
    $PathEntries = $UserPath -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

$AlreadyInPath = $false
foreach ($Entry in $PathEntries) {
    if ($Entry.TrimEnd([char]'\') -ieq $Su2Run.TrimEnd([char]'\')) {
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

$env:SU2_RUN = $Su2Run
$CurrentEntries = $env:Path -split ";"
if (-not ($CurrentEntries | Where-Object { $_.TrimEnd([char]'\') -ieq $Su2Run.TrimEnd([char]'\') })) {
    $env:Path = "$Su2Run;$env:Path"
}

Write-Host ""
Write-Host "Environment setup completed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "SU2_RUN:"
Write-Host "  $Su2Run"
Write-Host ""
Write-Host "Open a NEW Command Prompt and verify with:"
Write-Host "  echo %SU2_RUN%"
Write-Host "  where SU2_CFD"
Write-Host "  SU2_CFD"
Write-Host ""
