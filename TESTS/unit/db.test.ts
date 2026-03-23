import { DatabaseManager } from '../../db';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';

describe('DatabaseManager', () => {
  const testDbDir = path.join(os.tmpdir(), 'clawtools-test-' + Date.now());
  const testDbPath = path.join(testDbDir, 'test.db');

  beforeAll(() => {
    if (!fs.existsSync(testDbDir)) {
      fs.mkdirSync(testDbDir, { recursive: true });
    }
  });

  afterAll(() => {
    if (fs.existsSync(testDbDir)) {
      fs.rmSync(testDbDir, { recursive: true, force: true });
    }
  });

  describe('constructor', () => {
    it('should create database directory if not exists', () => {
      const dbPath = path.join(testDbDir, 'new.db');
      const db = new DatabaseManager(dbPath);
      expect(fs.existsSync(testDbDir)).toBe(true);
      db.close();
    });

    it('should create database with WAL mode', () => {
      const dbPath = path.join(testDbDir, 'wal-test.db');
      const db = new DatabaseManager(dbPath);
      db.close();
    });
  });

  describe('AppConfig operations', () => {
    let db: DatabaseManager;

    beforeEach(() => {
      db = new DatabaseManager(path.join(testDbDir, `appconfig-${Date.now()}.db`));
    });

    afterEach(() => {
      db.close();
    });

    it('should get default app config', () => {
      const config = db.getAppConfig();
      expect(config).toBeDefined();
      expect(config.id).toBe(1);
      expect(typeof config.encryptionEnabled).toBe('boolean');
      expect(typeof config.autoBackup).toBe('boolean');
    });

    it('should update app config', () => {
      const result = db.updateAppConfig({
        encryptionEnabled: true,
        autoBackup: true,
        backupInterval: 'weekly'
      });
      expect(result).toBe(true);

      const config = db.getAppConfig();
      expect(config.encryptionEnabled).toBe(true);
      expect(config.autoBackup).toBe(true);
      expect(config.backupInterval).toBe('weekly');
    });

    it('should update individual fields', () => {
      db.updateAppConfig({ encryptionEnabled: true });
      db.updateAppConfig({ autoBackup: false });

      const config = db.getAppConfig();
      expect(config.encryptionEnabled).toBe(true);
      expect(config.autoBackup).toBe(false);
    });
  });

  describe('Provider operations', () => {
    let db: DatabaseManager;

    beforeEach(() => {
      db = new DatabaseManager(path.join(testDbDir, `provider-${Date.now()}.db`));
    });

    afterEach(() => {
      db.close();
    });

    it('should add a provider', () => {
      const provider = {
        providerId: 'openai',
        name: 'OpenAI',
        baseURL: 'https://api.openai.com/v1',
        apiKeyEncrypted: 'encrypted-key',
        defaultModel: 'gpt-4',
        enabled: true
      };

      const id = db.addProvider(provider);
      expect(id).toBeDefined();
      expect(typeof id).toBe('number');
    });

    it('should get provider by id', () => {
      const provider = {
        providerId: 'test-provider',
        name: 'Test Provider',
        baseURL: 'https://test.com',
        apiKeyEncrypted: null,
        defaultModel: 'test-model',
        enabled: true
      };

      db.addProvider(provider);
      const retrieved = db.getProvider('test-provider');

      expect(retrieved).toBeDefined();
      expect(retrieved?.providerId).toBe('test-provider');
      expect(retrieved?.name).toBe('Test Provider');
      expect(retrieved?.enabled).toBe(true);
    });

    it('should return null for non-existent provider', () => {
      const retrieved = db.getProvider('non-existent');
      expect(retrieved).toBeNull();
    });

    it('should get all providers', () => {
      db.addProvider({
        providerId: 'provider1',
        name: 'Provider 1',
        baseURL: null,
        apiKeyEncrypted: null,
        defaultModel: null,
        enabled: true
      });
      db.addProvider({
        providerId: 'provider2',
        name: 'Provider 2',
        baseURL: null,
        apiKeyEncrypted: null,
        defaultModel: null,
        enabled: false
      });

      const providers = db.getAllProviders();
      expect(providers.length).toBeGreaterThanOrEqual(2);
    });

    it('should update provider', () => {
      db.addProvider({
        providerId: 'update-test',
        name: 'Original Name',
        baseURL: null,
        apiKeyEncrypted: null,
        defaultModel: null,
        enabled: true
      });

      const result = db.updateProvider('update-test', {
        name: 'Updated Name',
        enabled: false
      });
      expect(result).toBe(true);

      const provider = db.getProvider('update-test');
      expect(provider?.name).toBe('Updated Name');
      expect(provider?.enabled).toBe(false);
    });

    it('should delete provider', () => {
      db.addProvider({
        providerId: 'delete-test',
        name: 'Delete Me',
        baseURL: null,
        apiKeyEncrypted: null,
        defaultModel: null,
        enabled: true
      });

      const result = db.deleteProvider('delete-test');
      expect(result).toBe(true);

      const provider = db.getProvider('delete-test');
      expect(provider).toBeNull();
    });
  });

  describe('Backup record operations', () => {
    let db: DatabaseManager;

    beforeEach(() => {
      db = new DatabaseManager(path.join(testDbDir, `backup-${Date.now()}.db`));
    });

    afterEach(() => {
      db.close();
    });

    it('should add backup record', () => {
      const backup = {
        filename: 'backup-2024-01-01.tar.gz',
        path: '/backups/backup-2024-01-01.tar.gz',
        size: 1024000,
        options: JSON.stringify({ includeConfig: true })
      };

      const id = db.addBackupRecord(backup);
      expect(id).toBeDefined();
    });

    it('should get backup history', () => {
      db.addBackupRecord({
        filename: 'backup-1.tar.gz',
        path: '/backups/backup-1.tar.gz',
        size: 1000,
        options: '{}'
      });
      db.addBackupRecord({
        filename: 'backup-2.tar.gz',
        path: '/backups/backup-2.tar.gz',
        size: 2000,
        options: '{}'
      });

      const history = db.getBackupHistory(10);
      expect(history.length).toBeGreaterThanOrEqual(2);
    });
  });

  describe('History operations', () => {
    let db: DatabaseManager;

    beforeEach(() => {
      db = new DatabaseManager(path.join(testDbDir, `history-${Date.now()}.db`));
    });

    afterEach(() => {
      db.close();
    });

    it('should add history record', () => {
      db.addHistory('install', 'Installed OpenClaw v1.0.0');
      const history = db.getHistory(10);
      expect(history.length).toBeGreaterThan(0);
      expect(history[0].action).toBe('install');
    });

    it('should add history with null details', () => {
      db.addHistory('update');
      const history = db.getHistory(10);
      expect(history[0].details).toBeNull();
    });

    it('should limit history results', () => {
      for (let i = 0; i < 10; i++) {
        db.addHistory(`action-${i}`);
      }

      const limited = db.getHistory(5);
      expect(limited.length).toBeLessThanOrEqual(5);
    });
  });
});