import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import * as tar from 'tar';
import * as AdmZip from 'adm-zip';
import { fg } from 'fast-glob';

export interface BackupOptions {
  includeConfig: boolean;
  includeWorkspace: boolean;
  includeSkills: boolean;
  includePlugins: boolean;
  compressionLevel?: number;
}

export interface BackupResult {
  success: boolean;
  message: string;
  backupPath?: string;
  size?: number;
}

export interface RestoreResult {
  success: boolean;
  message: string;
}

export interface BackupInfo {
  id: string;
  timestamp: string;
  path: string;
  size: number;
  options: BackupOptions;
}

const DEFAULT_CONFIG_DIRS: Record<string, string> = {
  win32: path.join(os.homedir(), '.openclaw'),
  linux: path.join(os.homedir(), '.openclaw'),
  darwin: path.join(os.homedir(), '.openclaw'),
};

export class BackupManager {
  private configDir: string;
  private backupDir: string;

  constructor(configDir?: string, backupDir?: string) {
    const platform = process.platform;
    this.configDir = configDir || DEFAULT_CONFIG_DIRS[platform] || path.join(os.homedir(), '.openclaw');
    this.backupDir = backupDir || path.join(os.homedir(), '.clawtools', 'backups');

    if (!fs.existsSync(this.backupDir)) {
      fs.mkdirSync(this.backupDir, { recursive: true });
    }
  }

  public getBackupDir(): string {
    return this.backupDir;
  }

  public listBackups(): BackupInfo[] {
    try {
      const files = fs.readdirSync(this.backupDir);
      const backups: BackupInfo[] = [];

      for (const file of files) {
        if (file.endsWith('.tar.gz') || file.endsWith('.zip')) {
          const filePath = path.join(this.backupDir, file);
          const stat = fs.statSync(filePath);
          backups.push({
            id: path.basename(file, path.extname(file)),
            timestamp: stat.mtime.toISOString(),
            path: filePath,
            size: stat.size,
            options: { includeConfig: true, includeWorkspace: true, includeSkills: true, includePlugins: true },
          });
        }
      }

      return backups.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
    } catch {
      return [];
    }
  }

  public async createBackup(options: BackupOptions): Promise<BackupResult> {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupFileName = `openclaw-backup-${timestamp}.tar.gz`;
    const backupPath = path.join(this.backupDir, backupFileName);

    try {
      const filesToBackup: string[] = [];

      if (options.includeConfig && fs.existsSync(this.configDir)) {
        const configFiles = await fg('**/*', {
          cwd: this.configDir,
          onlyFiles: true,
          ignore: ['node_modules/**', '.git/**', '*.log'],
        });

        for (const file of configFiles) {
          const fullPath = path.join(this.configDir, file);
          const stat = fs.statSync(fullPath);
          if (stat.size < 50 * 1024 * 1024) {
            filesToBackup.push(file);
          }
        }
      }

      if (options.includeSkills) {
        const skillsDir = path.join(this.configDir, 'skills');
        if (fs.existsSync(skillsDir)) {
          const skillsFiles = await fg('**/*', {
            cwd: skillsDir,
            onlyFiles: true,
            ignore: ['node_modules/**'],
          });
          for (const file of skillsFiles) {
            filesToBackup.push(path.join('skills', file));
          }
        }
      }

      if (options.includePlugins) {
        const pluginsDir = path.join(this.configDir, 'plugins');
        if (fs.existsSync(pluginsDir)) {
          const pluginFiles = await fg('**/*', {
            cwd: pluginsDir,
            onlyFiles: true,
            ignore: ['node_modules/**'],
          });
          for (const file of pluginFiles) {
            filesToBackup.push(path.join('plugins', file));
          }
        }
      }

      if (filesToBackup.length === 0) {
        return { success: false, message: 'No files found to backup' };
      }

      await tar.create(
        {
          gzip: true,
          file: backupPath,
          cwd: this.configDir,
          level: options.compressionLevel || 6,
        },
        filesToBackup
      );

      const stats = fs.statSync(backupPath);

      const metadata = {
        version: '1.0',
        timestamp,
        options,
        files: filesToBackup,
        configDir: this.configDir,
      };

      const metadataPath = backupPath + '.meta.json';
      fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2), 'utf8');

      return {
        success: true,
        message: `Backup created successfully: ${backupFileName}`,
        backupPath,
        size: stats.size,
      };
    } catch (error: any) {
      return { success: false, message: `Backup failed: ${error.message}` };
    }
  }

  public async restoreBackup(backupPath: string, targetDir?: string): Promise<RestoreResult> {
    if (!fs.existsSync(backupPath)) {
      return { success: false, message: 'Backup file not found' };
    }

    const target = targetDir || this.configDir;

    try {
      await tar.extract({
        file: backupPath,
        cwd: target,
        strip: 0,
      });

      return { success: true, message: 'Backup restored successfully' };
    } catch (error: any) {
      try {
        const zip = new AdmZip(backupPath);
        zip.extractAllTo(target, true);
        return { success: true, message: 'Backup restored successfully' };
      } catch {
        return { success: false, message: `Restore failed: ${error.message}` };
      }
    }
  }

  public deleteBackup(backupPath: string): boolean {
    try {
      if (fs.existsSync(backupPath)) {
        fs.unlinkSync(backupPath);
      }
      const metaPath = backupPath + '.meta.json';
      if (fs.existsSync(metaPath)) {
        fs.unlinkSync(metaPath);
      }
      return true;
    } catch {
      return false;
    }
  }

  public async exportForMigration(targetPlatform: 'docker' | 'hyperv' | 'native'): Promise<string> {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const exportFileName = `openclaw-migration-${targetPlatform}-${timestamp}.tar.gz`;
    const exportPath = path.join(this.backupDir, exportFileName);

    const options: BackupOptions = {
      includeConfig: true,
      includeWorkspace: true,
      includeSkills: true,
      includePlugins: true,
    };

    const result = await this.createBackup(options);

    if (result.success && result.backupPath) {
      const migrationManifest = {
        platform: targetPlatform,
        timestamp: new Date().toISOString(),
        originalConfigDir: this.configDir,
        files: result.backupPath,
      };

      const manifestPath = exportPath + '.manifest.json';
      fs.writeFileSync(manifestPath, JSON.stringify(migrationManifest, null, 2), 'utf8');

      return exportPath;
    }

    throw new Error('Migration export failed');
  }
}
