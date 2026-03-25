import { execSync, exec } from 'child_process';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';

export interface NodeInfo {
  installed: boolean;
  version: string | null;
  path: string | null;
  meetsRequirement: boolean;
}

export interface OpenClawInfo {
  installed: boolean;
  version: string | null;
  path: string | null;
  configDir: string | null;
  configFile: string | null;
}

export interface SystemInfo {
  platform: 'windows' | 'linux' | 'darwin' | 'wsl';
  arch: string;
  homeDir: string;
  node: NodeInfo;
  openclaw: OpenClawInfo;
}

const OPENCLAW_CONFIG_DIRS: Record<string, string[]> = {
  win32: [
    path.join(os.homedir(), '.openclaw'),
    path.join(os.homedir(), 'AppData', 'Roaming', 'openclaw'),
  ],
  linux: [
    path.join(os.homedir(), '.openclaw'),
    path.join(os.homedir(), '.config', 'openclaw'),
  ],
  darwin: [
    path.join(os.homedir(), '.openclaw'),
    path.join(os.homedir(), 'Library', 'Application Support', 'openclaw'),
  ],
};

const OPENCLAW_CONFIG_FILES = ['config.json', 'config.js', 'settings.json'];

function getPlatform(): SystemInfo['platform'] {
  const platform = process.platform;
  if (platform === 'win32') {
    if (process.env.WSL_DISTRO_NAME || process.env.OSTYPE?.includes('linux')) {
      return 'wsl';
    }
    return 'windows';
  }
  if (platform === 'darwin') return 'darwin';
  return 'linux';
}

function detectNode(): NodeInfo {
  try {
    const version = execSync('node --version', { encoding: 'utf8' }).trim();
    const pathResult = execSync(process.platform === 'win32' ? 'where node' : 'which node', { encoding: 'utf8' }).trim();

    const semver = require('semver');
    const meetsRequirement = semver.gte(version, '20.0.0');

    return {
      installed: true,
      version,
      path: pathResult.split('\n')[0],
      meetsRequirement,
    };
  } catch {
    return {
      installed: false,
      version: null,
      path: null,
      meetsRequirement: false,
    };
  }
}

function detectOpenClaw(configDirs: string[]): OpenClawInfo {
  for (const dir of configDirs) {
    if (fs.existsSync(dir)) {
      for (const file of OPENCLAW_CONFIG_FILES) {
        const configPath = path.join(dir, file);
        if (fs.existsSync(configPath)) {
          try {
            const version = execSync('openclaw --version', { encoding: 'utf8', stdio: 'pipe' }).trim();
            return {
              installed: true,
              version,
              path: execSync(process.platform === 'win32' ? 'where openclaw' : 'which openclaw', { encoding: 'utf8', stdio: 'pipe' }).trim().split('\n')[0],
              configDir: dir,
              configFile: configPath,
            };
          } catch {
            return {
              installed: true,
              version: null,
              path: null,
              configDir: dir,
              configFile: configPath,
            };
          }
        }
      }
    }
  }

  try {
    const version = execSync('openclaw --version', { encoding: 'utf8', stdio: 'pipe' }).trim();
    return {
      installed: true,
      version,
      path: execSync(process.platform === 'win32' ? 'where openclaw' : 'which openclaw', { encoding: 'utf8', stdio: 'pipe' }).trim().split('\n')[0],
      configDir: null,
      configFile: null,
    };
  } catch {
    return {
      installed: false,
      version: null,
      path: null,
      configDir: null,
      configFile: null,
    };
  }
}

export function detectSystem(): SystemInfo {
  const platform = getPlatform();
  const configDirs = OPENCLAW_CONFIG_DIRS[platform] || OPENCLAW_CONFIG_DIRS.linux;

  return {
    platform,
    arch: process.arch,
    homeDir: os.homedir(),
    node: detectNode(),
    openclaw: detectOpenClaw(configDirs),
  };
}

export function checkFirewall(): Promise<{ enabled: boolean; ports: number[] }> {
  return new Promise((resolve) => {
    if (process.platform === 'win32') {
      exec('netsh advfirewall show allprofiles state', { encoding: 'utf8' }, (err, stdout) => {
        if (err) {
          resolve({ enabled: false, ports: [] });
          return;
        }
        const enabled = stdout.includes('ON');
        resolve({ enabled, ports: [] });
      });
    } else if (process.platform === 'darwin') {
      exec('defaults read /Library/Application\\ Support/com.apple.alf/globalstate', { encoding: 'utf8' }, (err) => {
        resolve({ enabled: !err, ports: [] });
      });
    } else {
      exec('ufw status', { encoding: 'utf8' }, (err, stdout) => {
        if (err) {
          resolve({ enabled: false, ports: [] });
          return;
        }
        const enabled = stdout.includes('active');
        resolve({ enabled, ports: [] });
      });
    }
  });
}

export async function checkPublicIP(): Promise<string | null> {
  try {
    // Use built-in fetch with AbortController for timeout (Node.js 18+)
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);
    const res = await fetch('https://api.ipify.org?format=json', { signal: controller.signal });
    clearTimeout(timeoutId);
    const data = await res.json() as { ip: string };
    return data.ip;
  } catch {
    return null;
  }
}

export async function detectPorts(port: number = 18789): Promise<boolean> {
  return new Promise((resolve) => {
    import('net').then(({ default: net }) => {
      const client = new net.Socket();

      client.connect(port, '127.0.0.1', () => {
        client.destroy();
        resolve(true);
      });

      client.on('error', () => {
        client.destroy();
        resolve(false);
      });

      client.setTimeout(1000, () => {
        client.destroy();
        resolve(false);
      });
    }).catch(() => resolve(false));
  });
}

export interface DockerInfo {
  installed: boolean;
  running: boolean;
  version: string | null;
  error?: string;
}

export interface WSLInfo {
  installed: boolean;
  version: string | null;
  distros: string[];
  defaultDistro: string | null;
}

export async function checkDockerStatus(): Promise<DockerInfo> {
  return new Promise((resolve) => {
    if (process.platform !== 'win32' && process.platform !== 'linux') {
      resolve({ installed: false, running: false, version: null, error: 'Docker Desktop is only available on Windows and Linux' });
      return;
    }

    // First check if docker command exists
    const whichCmd = process.platform === 'win32' ? 'where docker' : 'which docker';
    exec(whichCmd, { encoding: 'utf8' }, (err) => {
      if (err) {
        resolve({ installed: false, running: false, version: null, error: 'Docker command not found' });
        return;
      }

      // Try to get docker version
      exec('docker version', { encoding: 'utf8', timeout: 10000 }, (versionErr, versionStdout) => {
        if (versionErr) {
          // Docker installed but not running
          resolve({ installed: true, running: false, version: null, error: 'Docker is not running' });
          return;
        }

        // Parse version from output
        let version: string | null = null;
        const versionMatch = versionStdout.match(/Client version:\s*v?(\d+\.\d+\.\d+)/i);
        if (versionMatch) {
          version = versionMatch[1];
        }

        // Check if docker info works (confirms running state)
        exec('docker info', { encoding: 'utf8', timeout: 10000 }, (infoErr) => {
          resolve({
            installed: true,
            running: !infoErr,
            version,
            error: infoErr ? 'Docker daemon not accessible' : undefined,
          });
        });
      });
    });
  });
}

export async function checkWSLStatus(): Promise<WSLInfo> {
  return new Promise((resolve) => {
    if (process.platform !== 'win32') {
      resolve({ installed: false, version: null, distros: [], defaultDistro: null });
      return;
    }

    // Check WSL status
    exec('wsl --status', { encoding: 'utf8', timeout: 10000 }, (statusErr, statusStdout) => {
      if (statusErr) {
        resolve({ installed: false, version: null, distros: [], defaultDistro: null });
        return;
      }

      // Parse WSL version
      let version: string | null = null;
      const versionMatch = statusStdout.match(/WSL\s+(\d+)/i) || statusStdout.match(/version\s+(\d+)/i);
      if (versionMatch) {
        version = versionMatch[1];
      }

      // List installed distros
      exec('wsl --list', { encoding: 'utf8', timeout: 10000 }, (listErr, listStdout) => {
        const distros: string[] = [];
        let defaultDistro: string | null = null;

        if (!listErr) {
          const lines = listStdout.split('\n').filter((line) => line.trim() && !line.includes('---'));
          for (const line of lines) {
            const trimmed = line.trim();
            // Lines look like: "Ubuntu (Default)" or "docker-desktop-data *"
            const distroName = trimmed.replace(/\s*\([^)]*\)\s*\*?$/, '').trim();
            if (distroName) {
              distros.push(distroName);
              if (trimmed.includes('(Default)') || trimmed.endsWith('*')) {
                defaultDistro = distroName;
              }
            }
          }
          // If no default marker found, use first distro
          if (!defaultDistro && distros.length > 0) {
            defaultDistro = distros[0];
          }
        }

        resolve({
          installed: true,
          version,
          distros,
          defaultDistro,
        });
      });
    });
  });
}
