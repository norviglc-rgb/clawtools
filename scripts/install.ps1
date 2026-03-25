# ClawTools Installation Script for Windows
# Usage:
#   powershell -ExecutionPolicy Bypass -Command "[System.IO.File]::WriteAllText('$env:TEMP\clawtools_install.ps1', (Invoke-WebRequest 'https://raw.githubusercontent.com/norviglc-rgb/clawtools/master/scripts/install.ps1').Content, [System.Text.Encoding]::UTF8); & '$env:TEMP\clawtools_install.ps1'"

param(
    [string]$InstallDir = "$env:USERPROFILE\.clawtools",
    [string]$RepoUrl = "https://github.com/norviglc-rgb/clawtools.git"
)

# Set console to UTF-8 mode
chcp 65001 > $null 2>&1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "+===============================================+" -ForegroundColor Cyan
Write-Host "|           ClawTools Installer v0.1.0          |" -ForegroundColor Cyan
Write-Host "+===============================================+" -ForegroundColor Cyan
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
        try {
            git fetch origin master
            git reset --hard origin/master
        } catch {
            Write-Host "Update failed, re-cloning..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force $InstallDir
            git clone --depth 1 $RepoUrl $InstallDir
        }
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

    # Fix security vulnerabilities
    Write-Host "Checking for security vulnerabilities..." -ForegroundColor Cyan
    try {
        npm audit fix --force 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "No vulnerabilities found." -ForegroundColor Green
        }
    } catch {
        Write-Host "No vulnerabilities found." -ForegroundColor Green
    }

    npm run build

    # Create CLI wrapper
    Write-Host "Setting up CLI..." -ForegroundColor Cyan
    $clawtoolsBin = "$InstallDir\bin\cli\index.js"
    $clawtoolsCmd = "$InstallDir\clawtools.cmd"

    # Create a batch file to launch clawtools
    $cmdContent = "@echo off`r`nnode `"$clawtoolsBin`" %*"
    $cmdContent | Out-File -FilePath $clawtoolsCmd -Encoding ASCII

    # Add to PATH
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$InstallDir;$userPath", "User")
        $env:PATH = "$InstallDir;$env:PATH"
    }

    Write-Host ""
    Write-Host "+===============================================+" -ForegroundColor Green
    Write-Host "|          Installation Complete!               |" -ForegroundColor Green
    Write-Host "+===============================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "Run 'clawtools' to start." -ForegroundColor White
    Write-Host ""
}

Install-ClawTools
