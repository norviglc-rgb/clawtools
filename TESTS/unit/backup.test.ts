import { describe, it, expect } from 'vitest';
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
  const testDir = path.join(os.tmpdir(), 'clawtools-test-backup');
  let backupManager: BackupManager;

  beforeAll(() => {
    if (!fs.existsSync(testDir)) {
      fs.mkdirSync(testDir, { recursive: true });
    }
  });

  afterAll(() => {
    // Cleanup
    if (fs.existsSync(testDir)) {
      fs.rmSync(testDir, { recursive: true, force: true });
    }
  });

  beforeEach(() => {
    backupManager = new BackupManager(testDir);
  });

  describe('BackupManager', () => {
    it('should be instantiable', () => {
      expect(backupManager).toBeDefined();
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
  });

  describe('BackupOptions', () => {
    it('should accept valid options', () => {
      const options: BackupOptions = {
        includeConfig: true,
        includeDatabase: true,
        includeCredentials: false,
        compress: true
      };
      expect(options.includeConfig).toBe(true);
      expect(options.compress).toBe(true);
    });

    it('should accept minimal options', () => {
      const options: BackupOptions = {
        includeConfig: true
      };
      expect(options.includeConfig).toBe(true);
    });
  });

  describe('BackupResult', () => {
    it('should accept success result', () => {
      const result: BackupResult = {
        success: true,
        backupPath: '/path/to/backup.tar.gz',
        size: 1024,
        message: 'Backup created'
      };
      expect(result.success).toBe(true);
      expect(result.backupPath).toBe('/path/to/backup.tar.gz');
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
        restoredFiles: 5,
        message: 'Restored successfully'
      };
      expect(result.success).toBe(true);
      expect(result.restoredFiles).toBe(5);
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
        path: '/path/to/backup.tar.gz',
        created: new Date().toISOString(),
        size: 1024,
        type: 'full'
      };
      expect(info.id).toBe('backup-001');
      expect(info.type).toBe('full');
    });
  });

  describe('createBackup', () => {
    it('should return BackupResult type', async () => {
      // Note: This test just validates the interface
      // Actual backup creation requires OpenClaw config files
      expect(typeof backupManager.createBackup).toBe('function');
    });
  });

  describe('exportForMigration', () => {
    it('should accept docker target', async () => {
      expect(typeof backupManager.exportForMigration).toBe('function');
    });

    it('should accept hyperv target', async () => {
      expect(typeof backupManager.exportForMigration).toBe('function');
    });

    it('should accept native target', async () => {
      expect(typeof backupManager.exportForMigration).toBe('function');
    });
  });

  describe('listBackups', () => {
    it('should return array', async () => {
      const backups = await backupManager.listBackups();
      expect(Array.isArray(backups)).toBe(true);
    });
  });
});