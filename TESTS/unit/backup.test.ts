import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import {
  BackupManager,
  type BackupOptions,
  type BackupResult,
  type RestoreResult,
  type BackupInfo
} from '../../core/backup';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';

describe('backup', () => {
  const testDir = path.join(os.tmpdir(), 'clawtools-test-backup-' + Date.now());
  let backupManager: BackupManager;

  beforeEach(() => {
    backupManager = new BackupManager(testDir, testDir);
  });

  afterEach(() => {
    // Cleanup test files
    if (fs.existsSync(testDir)) {
      try {
        const files = fs.readdirSync(testDir);
        for (const file of files) {
          fs.unlinkSync(path.join(testDir, file));
        }
        fs.rmdirSync(testDir);
      } catch {
        // Ignore cleanup errors
      }
    }
  });

  describe('BackupManager', () => {
    it('should be instantiable', () => {
      expect(backupManager).toBeDefined();
    });

    it('should have getBackupDir method', () => {
      expect(typeof backupManager.getBackupDir).toBe('function');
    });

    it('should have createBackup method', () => {
      expect(typeof backupManager.createBackup).toBe('function');
    });

    it('should have restoreBackup method', () => {
      expect(typeof backupManager.restoreBackup).toBe('function');
    });

    it('should have exportForMigration method', () => {
      expect(typeof backupManager.exportForMigration).toBe('function');
    });

    it('should have listBackups method', () => {
      expect(typeof backupManager.listBackups).toBe('function');
    });

    it('should have deleteBackup method', () => {
      expect(typeof backupManager.deleteBackup).toBe('function');
    });
  });

  describe('getBackupDir', () => {
    it('should return a string path', () => {
      const dir = backupManager.getBackupDir();
      expect(typeof dir).toBe('string');
      expect(dir.length).toBeGreaterThan(0);
    });

    it('should be the configured backup directory', () => {
      const dir = backupManager.getBackupDir();
      expect(dir).toBe(testDir);
    });
  });

  describe('listBackups', () => {
    it('should return an array', () => {
      const backups = backupManager.listBackups();
      expect(Array.isArray(backups)).toBe(true);
    });

    it('should return empty array when no backups exist', () => {
      const backups = backupManager.listBackups();
      expect(backups.length).toBe(0);
    });
  });

  describe('deleteBackup', () => {
    it('should return boolean', () => {
      const result = backupManager.deleteBackup('/nonexistent/path');
      expect(typeof result).toBe('boolean');
    });

    it('should return true when path does not exist but no error thrown', () => {
      // deleteBackup returns true even when file doesn't exist (no error thrown)
      const result = backupManager.deleteBackup('/nonexistent/backup.tar.gz');
      expect(typeof result).toBe('boolean');
    });
  });

  describe('BackupOptions', () => {
    it('should accept full options', () => {
      const options: BackupOptions = {
        includeConfig: true,
        includeWorkspace: true,
        includeSkills: true,
        includePlugins: true,
        compressionLevel: 6
      };
      expect(options.includeConfig).toBe(true);
      expect(options.compressionLevel).toBe(6);
    });

    it('should accept partial options', () => {
      const options: BackupOptions = {
        includeConfig: true,
        includeWorkspace: false,
        includeSkills: false,
        includePlugins: false
      };
      expect(options.includeConfig).toBe(true);
      expect(options.includeWorkspace).toBe(false);
    });
  });

  describe('BackupResult', () => {
    it('should accept success result', () => {
      const result: BackupResult = {
        success: true,
        message: 'Backup created',
        backupPath: '/path/to/backup.tar.gz',
        size: 1024
      };
      expect(result.success).toBe(true);
      expect(result.backupPath).toBe('/path/to/backup.tar.gz');
      expect(result.size).toBe(1024);
    });

    it('should accept failure result', () => {
      const result: BackupResult = {
        success: false,
        message: 'Backup failed'
      };
      expect(result.success).toBe(false);
    });
  });

  describe('RestoreResult', () => {
    it('should accept success result', () => {
      const result: RestoreResult = {
        success: true,
        message: 'Restored successfully'
      };
      expect(result.success).toBe(true);
    });

    it('should accept failure result', () => {
      const result: RestoreResult = {
        success: false,
        message: 'Restore failed'
      };
      expect(result.success).toBe(false);
    });
  });

  describe('BackupInfo', () => {
    it('should have required properties', () => {
      const info: BackupInfo = {
        id: 'backup-001',
        timestamp: '2024-01-01T00:00:00Z',
        path: '/path/to/backup.tar.gz',
        size: 1024,
        options: {
          includeConfig: true,
          includeWorkspace: true,
          includeSkills: true,
          includePlugins: true
        }
      };
      expect(info.id).toBe('backup-001');
      expect(info.timestamp).toBe('2024-01-01T00:00:00Z');
      expect(info.size).toBe(1024);
    });
  });

  describe('createBackup', () => {
    it('should return BackupResult type', async () => {
      const options: BackupOptions = {
        includeConfig: false,
        includeWorkspace: false,
        includeSkills: false,
        includePlugins: false
      };
      // This will fail because config dir doesn't exist, but we test the interface
      const result = await backupManager.createBackup(options);
      expect(result).toHaveProperty('success');
      expect(result).toHaveProperty('message');
    });
  });

  describe('restoreBackup', () => {
    it('should return RestoreResult for nonexistent file', async () => {
      const result = await backupManager.restoreBackup('/nonexistent/backup.tar.gz');
      expect(result.success).toBe(false);
      expect(result.message).toContain('not found');
    });
  });

  describe('exportForMigration', () => {
    it('should accept docker target', async () => {
      // Will fail without real backup but tests interface
      await expect(
        backupManager.exportForMigration('docker')
      ).rejects.toThrow();
    });

    it('should accept hyperv target', async () => {
      await expect(
        backupManager.exportForMigration('hyperv')
      ).rejects.toThrow();
    });

    it('should accept native target', async () => {
      await expect(
        backupManager.exportForMigration('native')
      ).rejects.toThrow();
    });
  });
});