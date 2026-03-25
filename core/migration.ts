import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import * as tar from 'tar';
import * as crypto from 'crypto';

export type MigrationPlatform = 'docker' | 'hyperv' | 'native';
export type SourcePlatform = 'windows' | 'linux' | 'darwin' | 'wsl';

export interface PathMapping {
  source: string;
  target: string;
  description: string;
}

export interface PlatformConfig {
  platform: MigrationPlatform;
  configDir: string;
  dataDir: string;
  configFiles: string[];
  pathMappings: PathMapping[];
  envVars: Record<string, string>;
}

export interface MigrationManifest {
  version: string;
  timestamp: string;
  sourcePlatform: SourcePlatform;
  targetPlatform: MigrationPlatform;
  openClawVersion?: string;
  configFiles: string[];
  pathMappings: PathMapping[];
  checksum: string;
  instructions: string;
}

export interface MigrationExportResult {
  success: boolean;
  message: string;
  exportPath?: string;
  manifest?: MigrationManifest;
}

export interface MigrationImportResult {
  success: boolean;
  message: string;
  importedFiles?: number;
}

const PLATFORM_CONFIGS: Record<MigrationPlatform, PlatformConfig> = {
  docker: {
    platform: 'docker',
    configDir: '/home/app/.openclaw',
    dataDir: '/home/app/.openclaw',
    configFiles: ['config.json', 'config.js', 'settings.json'],
    pathMappings: [
      { source: '~/.openclaw', target: '/home/app/.openclaw', description: 'Config directory' },
      { source: '~/.config/openclaw', target: '/home/app/.openclaw', description: 'Linux config location' },
      { source: '~/Library/Application Support/openclaw', target: '/home/app/.openclaw', description: 'macOS config location' },
    ],
    envVars: {
      OPENCLAW_DATA: '/home/app/.openclaw',
      NODE_ENV: 'production',
    },
  },
  hyperv: {
    platform: 'hyperv',
    configDir: 'C:\\Users\\Public\\.openclaw',
    dataDir: 'C:\\ProgramData\\openclaw',
    configFiles: ['config.json', 'config.js', 'settings.json'],
    pathMappings: [
      { source: '~/.openclaw', target: 'C:\\Users\\Public\\.openclaw', description: 'Portable config directory' },
      { source: '~/.config/openclaw', target: 'C:\\Users\\Public\\.openclaw', description: 'Linux config location' },
      { source: '~/Library/Application Support/openclaw', target: 'C:\\Users\\Public\\.openclaw', description: 'macOS config location' },
    ],
    envVars: {
      OPENCLAW_DATA: 'C:\\Users\\Public\\.openclaw',
    },
  },
  native: {
    platform: 'native',
    configDir: '', // Use platform default
    dataDir: '',
    configFiles: ['config.json', 'config.js', 'settings.json'],
    pathMappings: [],
    envVars: {},
  },
};

function getSourcePlatform(): SourcePlatform {
  const platform = process.platform;
  if (platform === 'win32') {
    return process.env.WSL_DISTRO_NAME ? 'wsl' : 'windows';
  }
  if (platform === 'darwin') return 'darwin';
  return 'linux';
}

function getOpenClawConfigDirs(): string[] {
  const platform = process.platform;
  const home = os.homedir();
  const dirs: string[] = [];

  if (platform === 'win32') {
    dirs.push(path.join(home, '.openclaw'));
    dirs.push(path.join(home, 'AppData', 'Roaming', 'openclaw'));
    dirs.push(path.join(home, 'AppData', 'Local', 'openclaw'));
  } else if (platform === 'darwin') {
    dirs.push(path.join(home, '.openclaw'));
    dirs.push(path.join(home, 'Library', 'Application Support', 'openclaw'));
  } else {
    dirs.push(path.join(home, '.openclaw'));
    dirs.push(path.join(home, '.config', 'openclaw'));
  }

  return dirs.filter((d) => fs.existsSync(d));
}

function collectConfigFiles(configDir: string): string[] {
  const files: string[] = [];
  const configFiles = ['config.json', 'config.js', 'settings.json', '.env'];

  try {
    if (!fs.existsSync(configDir)) return files;

    for (const file of configFiles) {
      const filePath = path.join(configDir, file);
      if (fs.existsSync(filePath)) {
        files.push(file);
      }
    }

    // Also include skills and plugins directories if they exist
    const subDirs = ['skills', 'plugins', 'workspace', 'data'];
    for (const subDir of subDirs) {
      const subPath = path.join(configDir, subDir);
      if (fs.existsSync(subPath)) {
        files.push(subDir);
      }
    }
  } catch {
    // Ignore errors
  }

  return files;
}

function generateInstructions(sourcePlatform: SourcePlatform, targetPlatform: MigrationPlatform): string {
  const instructions: Record<MigrationPlatform, string> = {
    docker: `Docker Migration Instructions:
1. Copy the migration archive to your Docker host
2. Extract: tar -xzf openclaw-migration-docker-<timestamp>.tar.gz
3. Run the container: docker run -v ~/.openclaw:/home/app/.openclaw openclaw/openclaw
4. Your config will be available at /home/app/.openclaw inside the container`,

    hyperv: `Hyper-V Migration Instructions:
1. Copy the migration archive to your Hyper-V VM
2. Extract the archive to C:\\Users\\Public\\.openclaw
3. Set environment variable: OPENCLAW_DATA=C:\\Users\\Public\\.openclaw
4. Run OpenClaw normally`,

    native: `Native Migration Instructions:
1. Copy the migration archive to your new machine
2. Extract to your platform's config directory:
   - Windows: %USERPROFILE%\\.openclaw
   - macOS: ~/.openclaw
   - Linux: ~/.openclaw
3. Run OpenClaw normally`,
  };

  return instructions[targetPlatform];
}

function computeChecksum(data: string): string {
  return crypto.createHash('sha256').update(data).digest('hex').substring(0, 16);
}

export async function exportForMigration(targetPlatform: MigrationPlatform): Promise<MigrationExportResult> {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const exportFileName = `openclaw-migration-${targetPlatform}-${timestamp}.tar.gz`;
  const tempDir = os.tmpdir();
  const exportPath = path.join(tempDir, exportFileName);

  const sourcePlatform = getSourcePlatform();
  const configDirs = getOpenClawConfigDirs();

  if (configDirs.length === 0) {
    return {
      success: false,
      message: 'No OpenClaw configuration found to migrate',
    };
  }

  const primaryConfigDir = configDirs[0];
  const configFiles = collectConfigFiles(primaryConfigDir);

  if (configFiles.length === 0) {
    return {
      success: false,
      message: 'No configuration files found in OpenClaw directory',
    };
  }

  try {
    // Get OpenClaw version if available
    let openClawVersion: string | undefined;
    try {
      const { execSync } = require('child_process');
      openClawVersion = execSync('openclaw --version', { encoding: 'utf8', stdio: 'pipe' }).trim();
    } catch {
      // Version detection failed, continue without
    }

    // Get platform-specific config
    const platformConfig = PLATFORM_CONFIGS[targetPlatform];

    // Create manifest
    const manifest: MigrationManifest = {
      version: '1.0',
      timestamp: new Date().toISOString(),
      sourcePlatform,
      targetPlatform,
      openClawVersion,
      configFiles,
      pathMappings: platformConfig.pathMappings,
      checksum: '',
      instructions: generateInstructions(sourcePlatform, targetPlatform),
    };

    // Create archive with config files
    const filesToArchive: string[] = [...configFiles];

    // Add workspace if exists
    const workspacePath = path.join(primaryConfigDir, 'workspace');
    if (fs.existsSync(workspacePath)) {
      filesToArchive.push('workspace');
    }

    // Add skills if exists
    const skillsPath = path.join(primaryConfigDir, 'skills');
    if (fs.existsSync(skillsPath)) {
      filesToArchive.push('skills');
    }

    // Add plugins if exists
    const pluginsPath = path.join(primaryConfigDir, 'plugins');
    if (fs.existsSync(pluginsPath)) {
      filesToArchive.push('plugins');
    }

    await tar.create(
      {
        gzip: true,
        file: exportPath,
        cwd: primaryConfigDir,
      },
      filesToArchive
    );

    // Compute checksum of the archive
    const archiveData = fs.readFileSync(exportPath);
    manifest.checksum = computeChecksum(archiveData.toString('base64'));

    // Write manifest alongside archive
    const manifestPath = exportPath + '.manifest.json';
    fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');

    return {
      success: true,
      message: `Migration package created for ${targetPlatform}`,
      exportPath,
      manifest,
    };
  } catch (error: any) {
    return {
      success: false,
      message: `Migration export failed: ${error.message}`,
    };
  }
}

export async function importMigration(
  archivePath: string,
  targetPlatform: MigrationPlatform = 'native'
): Promise<MigrationImportResult> {
  if (!fs.existsSync(archivePath)) {
    return {
      success: false,
      message: 'Migration archive not found',
    };
  }

  // Verify manifest if exists
  const manifestPath = archivePath + '.manifest.json';
  let manifest: MigrationManifest | null = null;

  if (fs.existsSync(manifestPath)) {
    try {
      const manifestContent = fs.readFileSync(manifestPath, 'utf8');
      manifest = JSON.parse(manifestContent);
    } catch {
      // Manifest corrupted, continue without
    }
  }

  // Determine target config directory
  const platform = process.platform;
  let targetDir: string;

  if (targetPlatform === 'docker') {
    targetDir = '/home/app/.openclaw';
  } else if (targetPlatform === 'hyperv') {
    targetDir = 'C:\\Users\\Public\\.openclaw';
  } else {
    const home = os.homedir();
    targetDir = platform === 'win32'
      ? path.join(home, '.openclaw')
      : path.join(home, '.openclaw');
  }

  try {
    // Create target directory if needed
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    // Extract archive
    await tar.extract({
      file: archivePath,
      cwd: targetDir,
      strip: 0,
    });

    let importedFiles = 0;
    if (manifest) {
      importedFiles = manifest.configFiles.length;
    }

    return {
      success: true,
      message: `Migration imported to ${targetDir}`,
      importedFiles,
    };
  } catch (error: any) {
    return {
      success: false,
      message: `Migration import failed: ${error.message}`,
    };
  }
}

export function getMigrationPlatformConfig(platform: MigrationPlatform): PlatformConfig {
  return PLATFORM_CONFIGS[platform];
}

export function listMigrationPlatforms(): MigrationPlatform[] {
  return ['docker', 'hyperv', 'native'];
}