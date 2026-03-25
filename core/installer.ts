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
      exec(`"${scriptPath}"`);
      const version = execSync('node --version', { encoding: 'utf8' }).trim();
      resolve({ success: true, message: 'Node.js installed successfully', version });
    } catch (error: any) {
      resolve({ success: false, message: `Failed to install Node.js: ${error.message}` });
    } finally {
      try { fs.unlinkSync(scriptPath); } catch {}
    }
  });
}

const NPM_MIRRORS = [
  'https://registry.npmmirror.com',
  'https://mirrors.tuna.tsinghua.edu.cn/npm',
  'https://registry.npmmirror.org',
];

async function testMirror(mirror: string): Promise<boolean> {
  try {
    execSync(`npm view openclaw --registry=${mirror}`, { stdio: 'pipe', timeout: 10000 });
    return true;
  } catch {
    return false;
  }
}

export async function installOpenClaw(options: InstallOptions): Promise<InstallResult> {
  const { method, channel, version } = options;
  const versionSpec = version || (channel === 'stable' ? 'latest' : channel);
  const shell = process.platform === 'win32' ? 'cmd.exe' : '/bin/bash';

  // Docker method - no mirror needed
  if (method === 'docker') {
    try {
      execSync('docker pull openclaw/openclaw:latest', { stdio: 'inherit', shell });
      return { success: true, message: 'OpenClaw installed via Docker' };
    } catch (error: any) {
      return { success: false, message: `Docker install failed: ${error.message}` };
    }
  }

  // Script method - try official first, no mirror fallback
  if (method === 'script') {
    const scriptUrl = process.platform === 'win32'
      ? 'https://openclaw.ai/install.ps1'
      : 'https://openclaw.ai/install.sh';
    try {
      const cmd = process.platform === 'win32'
        ? `iwr -useb ${scriptUrl} | iex`
        : `curl -fsSL ${scriptUrl} | bash`;
      execSync(cmd, { stdio: 'inherit', shell });
      return { success: true, message: 'OpenClaw installed via script' };
    } catch (error: any) {
      return { success: false, message: `Script install failed: ${error.message}` };
    }
  }

  // NPM method - intelligent mirror fallback
  console.log('[ClawTools] Detecting best npm mirror...');

  // First, find a working mirror
  let workingMirror = NPM_MIRRORS[0];
  for (const mirror of NPM_MIRRORS) {
    process.stdout.write(`  Testing ${mirror}... `);
    if (await testMirror(mirror)) {
      console.log('OK');
      workingMirror = mirror;
      break;
    } else {
      console.log('FAILED');
    }
  }

  // If first mirror fails, try all others
  if (!(await testMirror(workingMirror))) {
    for (const mirror of NPM_MIRRORS) {
      if (mirror === workingMirror) continue;
      process.stdout.write(`  Retrying with ${mirror}... `);
      if (await testMirror(mirror)) {
        console.log('OK');
        workingMirror = mirror;
        break;
      } else {
        console.log('FAILED');
      }
    }
  }

  // Install with working mirror
  const installCmd = `npm install -g openclaw@${versionSpec} --registry=${workingMirror}`;
  console.log(`[ClawTools] Installing from ${workingMirror}...`);

  try {
    execSync(installCmd, { stdio: 'inherit', shell });
  } catch (error: any) {
    // If mirror install fails, try official registry as last resort
    console.log('[ClawTools] Mirror failed, trying official registry...');
    try {
      execSync(`npm install -g openclaw@${versionSpec}`, { stdio: 'inherit', shell });
      workingMirror = 'https://registry.npmjs.org';
    } catch (finalError: any) {
      return {
        success: false,
        message: `All npm mirrors failed. Last error: ${finalError.message}`,
      };
    }
  }

  // Verify installation
  try {
    const installedVersion = execSync('openclaw --version', { encoding: 'utf8' }).trim();
    const installPath = execSync(
      process.platform === 'win32' ? 'where openclaw' : 'which openclaw',
      { encoding: 'utf8' }
    ).trim().split('\n')[0];

    return {
      success: true,
      message: `OpenClaw ${installedVersion} installed successfully via ${workingMirror}`,
      version: installedVersion,
      path: installPath,
    };
  } catch (error: any) {
    return {
      success: false,
      message: `Install succeeded but verification failed: ${error.message}`,
    };
  }
}

export async function uninstallOpenClaw(): Promise<InstallResult> {
  try {
    execSync('npm uninstall -g openclaw --registry=https://registry.npmmirror.com', { stdio: 'inherit' });

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
    const output = execSync('npm view openclaw versions --json --registry=https://registry.npmmirror.com', { encoding: 'utf8' });
    const versions = JSON.parse(output);
    return versions.slice(-20);
  } catch {
    return ['latest', 'beta', 'dev'];
  }
}
