# Node.js installation script for Windows (PowerShell)

param(
    [string]$Version = "latest"
)

$ErrorActionPreference = "Stop"

function Get-NodeVersion {
    try {
        $version = node --version 2>$null
        return $version
    } catch {
        return $null
    }
}

function Install-Node {
    param([string]$TargetVersion)

    Write-Host "Node.js not found or version is too old. Installing Node.js..." -ForegroundColor Yellow

    $nodeUrl = if ($TargetVersion -eq "latest") {
        "https://nodejs.org/dist/latest/win-x64/node.exe"
    } else {
        "https://nodejs.org/dist/v$TargetVersion/win-x64/node.exe"
    }

    $tempDir = $env:TEMP
    $nodeExePath = Join-Path $tempDir "node.exe"
    $installPath = "$env:ProgramFiles\nodejs"

    Write-Host "Downloading Node.js from $nodeUrl..."

    try {
        # Download Node.js binary
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeExePath -UseBasicParsing

        # Create install directory
        if (-not (Test-Path $installPath)) {
            New-Item -ItemType Directory -Path $installPath -Force | Out-Null
        }

        # Move to install location
        Move-Item -Path $nodeExePath -Destination "$installPath\node.exe" -Force

        # Add to PATH for current session
        $env:PATH = "$installPath;$env:PATH"

        # Add to system PATH permanently
        $machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($machinePath -notlike "*$installPath*") {
            [Environment]::SetEnvironmentVariable("PATH", "$installPath;$machinePath", "Machine")
        }

        Write-Host "Node.js installed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to download Node.js: $_" -ForegroundColor Red
        return $false
    }

    return $true
}

Write-Host "Checking for Node.js..." -ForegroundColor Cyan

$currentVersion = Get-NodeVersion

if ($currentVersion) {
    Write-Host "Node.js $currentVersion is already installed" -ForegroundColor Green

    # Parse version
    $versionMatch = [regex]::Match($currentVersion, 'v?(\d+)\.')
    if ($versionMatch.Success) {
        $majorVersion = [int]$versionMatch.Groups[1].Value
        if ($majorVersion -lt 20) {
            Write-Host "Node.js version 20+ is required. Upgrading..." -ForegroundColor Yellow
            Install-Node -TargetVersion $Version
        }
    }
} else {
    Write-Host "Node.js not found. Installing..." -ForegroundColor Yellow
    Install-Node -TargetVersion $Version
}

# Verify installation
Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Cyan
node --version
npm --version

Write-Host ""
Write-Host "Node.js installation complete!" -ForegroundColor Green
