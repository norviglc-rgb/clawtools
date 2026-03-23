# ClawTools Installation Script for Windows
# Usage: iwr -useb https://raw.githubusercontent.com/YOUR_USERNAME/clawtools/main/scripts/install.ps1 | iex

param(
    [string]$InstallDir = "$env:USERPROFILE\.clawtools",
    [string]$RepoUrl = "https://github.com/YOUR_USERNAME/clawtools.git"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           ClawTools Installer v0.1.0          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check Node.js
function Test-NodeInstalled {
    try {
        $version = node --version 2>$null
        return $version
    } catch {
        return $null
    }
}

# Install Node.js if needed
function Install-NodeIfNeeded {
    $nodeVersion = Test-NodeInstalled

    if (-not $nodeVersion) {
        Write-Host "Node.js not found. Installing Node.js..." -ForegroundColor Yellow

        $nodeUrl = "https://nodejs.org/dist/latest/win-x64/node.exe"
        $nodePath = "$env:TEMP\node.exe"

        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $nodeUrl -OutFile $nodePath -UseBasicParsing

            $installPath = "$env:ProgramFiles\nodejs"
            if (-not (Test-Path $installPath)) {
                New-Item -ItemType Directory -Path $installPath -Force | Out-Null
            }

            Move-Item -Path $nodePath -Destination "$installPath\node.exe" -Force

            $env:PATH = "$installPath;$env:PATH"
            $machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
            if ($machinePath -notlike "*$installPath*") {
                [Environment]::SetEnvironmentVariable("PATH", "$installPath;$machinePath", "Machine")
            }

            Write-Host "Node.js installed successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Failed to install Node.js: $_" -ForegroundColor Red
            Write-Host "Please install Node.js manually from https://nodejs.org" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "Node.js $nodeVersion found" -ForegroundColor Green
    }
}

# Main installation
function Install-ClawTools {
    # Check Node.js
    Install-NodeIfNeeded

    # Create installation directory
    Write-Host "Creating installation directory..." -ForegroundColor Cyan
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    # Clone or update repository
    Write-Host "Cloning/updating ClawTools..." -ForegroundColor Cyan
    if (Test-Path "$InstallDir\.git") {
        Set-Location $InstallDir
        git pull origin main
    } else {
        if (Test-Path $InstallDir) {
            Remove-Item -Recurse -Force $InstallDir
        }
        git clone --depth 1 $RepoUrl $InstallDir
    }

    # Install dependencies and build
    Write-Host "Installing dependencies..." -ForegroundColor Cyan
    Set-Location $InstallDir
    npm install
    npm run build

    # Create symlink in PATH
    Write-Host "Setting up CLI..." -ForegroundColor Cyan
    $clawtoolsBin = "$InstallDir\bin\index.js"
    $targetBin = "$env:LOCALAPPDATA\Microsoft\WindowsApps\clawtools.cmd"

    $cmdContent = "@echo off`n`touch `"$clawtoolsBin`"`n`tnode `"$clawtoolsBin`" %*"
    $cmdContent | Out-File -FilePath "$InstallDir\clawtools.cmd" -Encoding ASCII

    # Add to PATH
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$InstallDir;$userPath", "User")
        $env:PATH = "$InstallDir;$env:PATH"
    }

    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║        Installation Complete!                ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Run 'clawtools' to start." -ForegroundColor White
    Write-Host ""
}

Install-ClawTools
