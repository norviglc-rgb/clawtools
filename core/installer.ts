import { execSync, exec } from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';

export type InstallChannel = 'stable' | 'beta' | 'dev';
export type InstallMethod = 'npm' | 'script' | 'docker';
export type InstallPlatform = 'native' | 'docker' | 'wsl';

export interface DockerInstallResult {
  success: boolean;
  message: string;
  dockerVersion?: string;
}

export interface WSLInstallResult {
  success: boolean;
  message: string;
  distro?: string;
}

export interface InstallOptions {
  method: InstallMethod;
  channel: InstallChannel;
  platform: InstallPlatform;
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

export async function installDocker(): Promise<DockerInstallResult> {
  if (process.platform !== 'win32' && process.platform !== 'linux') {
    return { success: false, message: 'Docker Desktop is only available on Windows and Linux' };
  }

  return new Promise((resolve) => {
    const { execSync } = require('child_process');

    // Check if Docker is already installed
    try {
      const versionOutput = execSync('docker --version', { encoding: 'utf8' }).trim();
      const versionMatch = versionOutput.match(/(\d+\.\d+\.\d+)/);
      const dockerVersion = versionMatch ? versionMatch[1] : null;
      resolve({ success: true, message: `Docker is already installed (${versionOutput})`, dockerVersion });
      return;
    } catch {}

    if (process.platform === 'win32') {
      // Windows: Download and install Docker Desktop silently
      try {
        console.log('[ClawTools] Downloading Docker Desktop for Windows...');
        const dockerUrl = 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe';
        const installerPath = path.join(os.tmpdir(), 'docker-desktop-installer.exe');

        execSync(`powershell -Command "Invoke-WebRequest -Uri '${dockerUrl}' -OutFile '${installerPath}'"`, { stdio: 'inherit' });

        console.log('[ClawTools] Installing Docker Desktop (this may take a few minutes)...');
        execSync(`"${installerPath}" install --quiet`, { stdio: 'inherit' });

        // Clean up installer
        try { fs.unlinkSync(installerPath); } catch {}

        console.log('[ClawTools] Waiting for Docker service to start...');
        // Wait for Docker to start (max 60 seconds)
        const maxWait = 60;
        let dockerReady = false;
        for (let i = 0; i < maxWait; i++) {
          try {
            execSync('docker info', { stdio: 'pipe' });
            dockerReady = true;
            break;
          } catch {
            execSync('timeout /t 1 /nobreak > nul', { stdio: 'pipe' });
          }
        }

        if (dockerReady) {
          const versionOutput = execSync('docker --version', { encoding: 'utf8' }).trim();
          const versionMatch = versionOutput.match(/(\d+\.\d+\.\d+)/);
          resolve({
            success: true,
            message: 'Docker Desktop installed and running successfully',
            dockerVersion: versionMatch ? versionMatch[1] : undefined,
          });
        } else {
          resolve({ success: true, message: 'Docker Desktop installed - please restart your computer or start Docker manually' });
        }
      } catch (error: any) {
        resolve({ success: false, message: `Docker Desktop installation failed: ${error.message}` });
      }
    } else {
      // Linux: Use package manager
      try {
        console.log('[ClawTools] Installing Docker on Linux...');
        execSync('curl -fsSL https://get.docker.com -o /tmp/get-docker.sh', { stdio: 'inherit' });
        execSync('sh /tmp/get-docker.sh', { stdio: 'inherit' });
        execSync('rm -f /tmp/get-docker.sh', { stdio: 'pipe' });

        // Add current user to docker group
        try {
          execSync('sudo usermod -aG docker $USER', { stdio: 'inherit' });
        } catch {}

        const versionOutput = execSync('docker --version', { encoding: 'utf8' }).trim();
        const versionMatch = versionOutput.match(/(\d+\.\d+\.\d+)/);
        resolve({
          success: true,
          message: 'Docker installed successfully',
          dockerVersion: versionMatch ? versionMatch[1] : undefined,
        });
      } catch (error: any) {
        resolve({ success: false, message: `Docker installation failed: ${error.message}` });
      }
    }
  });
}

export async function installWSL(): Promise<WSLInstallResult> {
  if (process.platform !== 'win32') {
    return { success: false, message: 'WSL is only available on Windows' };
  }

  return new Promise((resolve) => {
    const { execSync } = require('child_process');

    // Check if WSL is already installed
    try {
      const statusOutput = execSync('wsl --status', { encoding: 'utf8' }).trim();
      const listOutput = execSync('wsl --list', { encoding: 'utf8' }).trim();
      const lines = listOutput.split('\n').filter((line: string) => line.trim() && !line.includes('---'));
      const distros: string[] = [];
      let defaultDistro: string | null = null;

      for (const line of lines) {
        const trimmed = line.trim();
        const distroName = trimmed.replace(/\s*\([^)]*\)\s*\*?$/, '').trim();
        if (distroName) {
          distros.push(distroName);
          if (trimmed.includes('(Default)') || trimmed.endsWith('*')) {
            defaultDistro = distroName;
          }
        }
      }

      if (distros.length > 0) {
        resolve({
          success: true,
          message: `WSL is already installed with ${distros.length} distro(s)`,
          distro: defaultDistro || distros[0],
        });
        return;
      }
    } catch {}

    // Install WSL
    try {
      console.log('[ClawTools] Enabling Windows Subsystem for Linux...');
      execSync('powershell -Command "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"', { stdio: 'inherit' });

      console.log('[ClawTools] Installing Ubuntu as the default Linux distribution...');
      execSync('wsl --install -d Ubuntu', { stdio: 'inherit' });

      console.log('[ClawTools] WSL installation initiated - a restart may be required');
      resolve({
        success: true,
        message: 'WSL and Ubuntu have been installed - please restart your computer if prompted',
        distro: 'Ubuntu',
      });
    } catch (error: any) {
      // If standard install fails, try online installation method
      try {
        console.log('[ClawTools] Trying online WSL installation...');
        execSync('powershell -Command "wsl --install --online"', { stdio: 'inherit' });
        resolve({
          success: true,
          message: 'WSL installed successfully',
          distro: 'Ubuntu',
        });
      } catch (retryError: any) {
        resolve({ success: false, message: `WSL installation failed: ${retryError.message}` });
      }
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
  const { method, channel, platform, version } = options;
  const versionSpec = version || (channel === 'stable' ? 'latest' : channel);
  const shell = process.platform === 'win32' ? 'cmd.exe' : '/bin/bash';

  // Platform-specific installation
  if (platform === 'docker') {
    // Docker platform - run OpenClaw in a Docker container
    try {
      const dockerImage = `openclaw/openclaw:${versionSpec}`;
      console.log(`[ClawTools] Pulling Docker image ${dockerImage}...`);
      execSync(`docker pull ${dockerImage}`, { stdio: ['inherit', 'pipe', 'pipe'], shell });
      return {
        success: true,
        message: `OpenClaw is available via Docker: docker run ${dockerImage}`,
        path: dockerImage,
      };
    } catch (error: any) {
      // Capture stderr for detailed error message
      const stderr = error.stderr ? error.stderr.toString() : '';
      const detailMsg = stderr.trim() || error.message;
      return { success: false, message: `Docker 拉取失败: ${detailMsg}` };
    }
  }

  if (platform === 'wsl') {
    // WSL platform - install inside WSL
    if (process.platform !== 'win32') {
      return { success: false, message: 'WSL platform is only available on Windows' };
    }
    try {
      console.log('[ClawTools] Installing OpenClaw inside WSL...');
      // Run installation inside WSL Ubuntu
      const wslInstallCmd = `wsl -d Ubuntu -e bash -c "curl -fsSL https://openclaw.ai/install.sh | bash"`;
      execSync(wslInstallCmd, { stdio: 'inherit' });
      return { success: true, message: 'OpenClaw installed inside WSL' };
    } catch (error: any) {
      return { success: false, message: `WSL installation failed: ${error.message}` };
    }
  }

  // Native platform installation
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

export interface VersionInfo {
  version: string;
  channel: InstallChannel;
  isLatest: boolean;
}

export interface VersionListResult {
  success: boolean;
  versions: VersionInfo[];
  error?: string;
}

function parseChannel(version: string): InstallChannel {
  if (version.includes('beta')) return 'beta';
  if (version.includes('dev') || version.includes('alpha')) return 'dev';
  return 'stable';
}

export async function getVersionList(): Promise<VersionListResult> {
  const NPM_MIRRORS = [
    'https://registry.npmmirror.com',
    'https://registry.npmmirror.org',
    'https://registry.npmjs.org',
  ];

  for (const mirror of NPM_MIRRORS) {
    try {
      const output = execSync(`npm view openclaw versions --json --registry=${mirror}`, {
        encoding: 'utf8',
        timeout: 15000,
      });
      const allVersions: string[] = JSON.parse(output);

      // Get dist-tags to find latest
      const tagsOutput = execSync(`npm view openclaw dist-tags --json --registry=${mirror}`, {
        encoding: 'utf8',
        timeout: 15000,
      });
      const distTags: Record<string, string> = JSON.parse(tagsOutput);
      const latestVersion = distTags['latest'] || '';

      // Get last 30 versions and reverse to show newest first
      const recentVersions = allVersions.slice(-30).reverse();

      const versionInfos: VersionInfo[] = recentVersions.map((v) => ({
        version: v,
        channel: parseChannel(v),
        isLatest: v === latestVersion,
      }));

      return { success: true, versions: versionInfos };
    } catch {
      continue;
    }
  }

  return {
    success: false,
    versions: [],
    error: 'Failed to fetch versions from all mirrors',
  };
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
