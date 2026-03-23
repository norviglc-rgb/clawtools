import { execSync, exec } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';

export type InstallChannel = 'stable' | 'beta' | 'dev';
export type InstallMethod = 'npm' | 'script' | 'docker';

export interface InstallOptions {
  method: InstallMethod;
  channel: InstallChannel;
  version?: string;
  global?: boolean;
}

export interface InstallResult {
  success: boolean;
  message: string;
  version?: string;
  path?: string;
}

export interface NodeInstallResult {
  success: boolean;
  message: string;
  version?: string;
}

const NODE_INSTALL_SCRIPTS = {
  win32: `if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    $ErrorActionPreference = "Stop"
    Write-Host "Installing Node.js via Node.js Installer..."
    $nodeUrl = "https://nodejs.org/dist/latest/win-x64/node.exe"
    $nodePath = "$env:TEMP\\node.exe"
    Invoke-WebRequest -Uri $nodeUrl -OutFile $nodePath
    $installPath = "$env:ProgramFiles\\nodejs"
    Move-Item -Path $nodePath -Destination "$installPath\\node.exe" -Force
    $env:PATH = "$installPath;$env:PATH"
    [Environment]::SetEnvironmentVariable("PATH", "$installPath;$env:PATH", "Machine")
    Write-Host "Node.js installed successfully"
    Remove-Item $nodePath -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Node.js is already installed"
}`,
  linux: `#!/bin/bash
if ! command -v node &> /dev/null; then
    echo "Installing Node.js via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
else
    echo "Node.js is already installed"
fi`,
  darwin: `#!/bin/bash
if ! command -v node &> /dev/null; then
    echo "Installing Node.js via Homebrew..."
    brew install node@20
else
    echo "Node.js is already installed"
fi`,
};

export async function installNode(platform: string): Promise<NodeInstallResult> {
  const script = NODE_INSTALL_SCRIPTS[platform as keyof typeof NODE_INSTALL_SCRIPTS];

  if (!script) {
    return { success: false, message: `Unsupported platform: ${platform}` };
  }

  return new Promise((resolve) => {
    const { execSync } = require('child_process');
    const tmpDir = os.tmpdir();
    const ext = platform === 'win32' ? '.ps1' : '.sh';
    const scriptPath = path.join(tmpDir, `node_install${ext}`);

    try {
      fs.writeFileSync(scriptPath, script, { mode: 0o755 });
      exec(`"${scriptPath}"`, { stdio: 'inherit' });
      const version = execSync('node --version', { encoding: 'utf8' }).trim();
      resolve({ success: true, message: 'Node.js installed successfully', version });
    } catch (error: any) {
      resolve({ success: false, message: `Failed to install Node.js: ${error.message}` });
    } finally {
      try { fs.unlinkSync(scriptPath); } catch {}
    }
  });
}

export function getOpenClawInstallCommand(options: InstallOptions): string {
  const channel = options.channel === 'stable' ? '@latest' : `@${options.channel}`;

  switch (options.method) {
    case 'npm':
      return `npm install -g openclaw${channel}`;
    case 'script':
      return platform === 'win32'
        ? 'iwr -useb https://openclaw.ai/install.ps1 | iex'
        : 'curl -fsSL https://openclaw.ai/install.sh | bash';
    case 'docker':
      return 'docker pull openclaw/openclaw';
    default:
      return `npm install -g openclaw${channel}`;
  }
}

export async function installOpenClaw(options: InstallOptions): Promise<InstallResult> {
  const { method, channel, version } = options;

  try {
    let command: string;

    if (method === 'docker') {
      command = 'docker pull openclaw/openclaw:latest';
    } else if (method === 'script') {
      const platform = process.platform;
      command = platform === 'win32'
        ? 'iwr -useb https://openclaw.ai/install.ps1 | iex'
        : 'curl -fsSL https://openclaw.ai/install.sh | bash';
    } else {
      const versionSpec = version || (channel === 'stable' ? 'latest' : channel);
      command = `npm install -g openclaw@${versionSpec}`;
    }

    execSync(command, { stdio: 'inherit', shell: process.platform === 'win32' ? 'cmd.exe' : '/bin/bash' });

    const installedVersion = execSync('openclaw --version', { encoding: 'utf8' }).trim();
    const installPath = execSync(
      process.platform === 'win32' ? 'where openclaw' : 'which openclaw',
      { encoding: 'utf8' }
    ).trim().split('\n')[0];

    return {
      success: true,
      message: `OpenClaw ${installedVersion} installed successfully`,
      version: installedVersion,
      path: installPath,
    };
  } catch (error: any) {
    return {
      success: false,
      message: `Installation failed: ${error.message}`,
    };
  }
}

export async function uninstallOpenClaw(): Promise<InstallResult> {
  try {
    execSync('npm uninstall -g openclaw', { stdio: 'inherit' });

    const platform = process.platform;
    const configPaths = platform === 'win32'
      ? [path.join(os.homedir(), '.openclaw'), path.join(os.homedir(), 'AppData', 'Roaming', 'openclaw')]
      : [path.join(os.homedir(), '.openclaw')];

    const cleanChoice = 'y';
    if (cleanChoice === 'y') {
      for (const configPath of configPaths) {
        if (fs.existsSync(configPath)) {
          fs.rmSync(configPath, { recursive: true, force: true });
        }
      }
    }

    return { success: true, message: 'OpenClaw uninstalled successfully' };
  } catch (error: any) {
    return { success: false, message: `Uninstall failed: ${error.message}` };
  }
}

export function getAvailableVersions(): string[] {
  try {
    const output = execSync('npm view openclaw versions --json', { encoding: 'utf8' });
    const versions = JSON.parse(output);
    return versions.slice(-20);
  } catch {
    return ['latest', 'beta', 'dev'];
  }
}
