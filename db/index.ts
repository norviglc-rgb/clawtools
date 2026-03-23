import Database from 'better-sqlite3';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';

export interface AppConfig {
  id: number;
  encryptionEnabled: boolean;
  autoBackup: boolean;
  backupInterval: string;
  lastBackup: string | null;
  docsCloned: boolean;
  docsCloneDate: string | null;
}

export interface ProviderRecord {
  id: number;
  providerId: string;
  name: string;
  baseURL: string | null;
  apiKeyEncrypted: string | null;
  defaultModel: string | null;
  enabled: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface BackupRecord {
  id: number;
  filename: string;
  path: string;
  size: number;
  options: string;
  createdAt: string;
}

export interface HistoryRecord {
  id: number;
  action: string;
  details: string | null;
  createdAt: string;
}

export class DatabaseManager {
  private db: Database.Database;
  private dbPath: string;

  constructor(dbPath?: string) {
    const dbDir = dbPath ? path.dirname(dbPath) : path.join(os.homedir(), '.clawtools');
    if (!fs.existsSync(dbDir)) {
      fs.mkdirSync(dbDir, { recursive: true });
    }

    this.dbPath = dbPath || path.join(dbDir, 'clawtools.db');
    this.db = new Database(this.dbPath);
    this.db.pragma('journal_mode = WAL');
    this.init();
  }

  private init(): void {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS app_config (
        id INTEGER PRIMARY KEY DEFAULT 1,
        encryption_enabled INTEGER DEFAULT 0,
        auto_backup INTEGER DEFAULT 0,
        backup_interval TEXT DEFAULT 'daily',
        last_backup TEXT,
        docs_cloned INTEGER DEFAULT 0,
        docs_clone_date TEXT
      );

      CREATE TABLE IF NOT EXISTS providers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        base_url TEXT,
        api_key_encrypted TEXT,
        default_model TEXT,
        enabled INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS backups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filename TEXT NOT NULL,
        path TEXT NOT NULL,
        size INTEGER NOT NULL,
        options TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        details TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      );

      INSERT OR IGNORE INTO app_config (id) VALUES (1);
    `);
  }

  public getAppConfig(): AppConfig {
    const row = this.db.prepare('SELECT * FROM app_config WHERE id = 1').get() as any;
    return {
      id: row.id,
      encryptionEnabled: Boolean(row.encryption_enabled),
      autoBackup: Boolean(row.auto_backup),
      backupInterval: row.backup_interval,
      lastBackup: row.last_backup,
      docsCloned: Boolean(row.docs_cloned),
      docsCloneDate: row.docs_clone_date,
    };
  }

  public updateAppConfig(config: Partial<AppConfig>): boolean {
    const updates: string[] = [];

    if (config.encryptionEnabled !== undefined) {
      updates.push(`encryption_enabled = ${config.encryptionEnabled ? 1 : 0}`);
    }
    if (config.autoBackup !== undefined) {
      updates.push(`auto_backup = ${config.autoBackup ? 1 : 0}`);
    }
    if (config.backupInterval !== undefined) {
      updates.push(`backup_interval = '${config.backupInterval}'`);
    }
    if (config.lastBackup !== undefined) {
      updates.push(`last_backup = '${config.lastBackup}'`);
    }
    if (config.docsCloned !== undefined) {
      updates.push(`docs_cloned = ${config.docsCloned ? 1 : 0}`);
    }
    if (config.docsCloneDate !== undefined) {
      updates.push(`docs_clone_date = '${config.docsCloneDate}'`);
    }

    if (updates.length === 0) return false;

    try {
      this.db.prepare(`UPDATE app_config SET ${updates.join(', ')} WHERE id = 1`).run();
      return true;
    } catch {
      return false;
    }
  }

  public addProvider(provider: Omit<ProviderRecord, 'id' | 'createdAt' | 'updatedAt'>): number | null {
    try {
      const result = this.db.prepare(`
        INSERT INTO providers (provider_id, name, base_url, api_key_encrypted, default_model, enabled)
        VALUES (?, ?, ?, ?, ?, ?)
      `).run(
        provider.providerId,
        provider.name,
        provider.baseURL,
        provider.apiKeyEncrypted,
        provider.defaultModel,
        provider.enabled ? 1 : 0
      );
      return result.lastInsertRowid as number;
    } catch {
      return null;
    }
  }

  public updateProvider(providerId: string, updates: Partial<ProviderRecord>): boolean {
    const setClauses: string[] = [];
    const values: any[] = [];

    if (updates.name !== undefined) {
      setClauses.push('name = ?');
      values.push(updates.name);
    }
    if (updates.baseURL !== undefined) {
      setClauses.push('base_url = ?');
      values.push(updates.baseURL);
    }
    if (updates.apiKeyEncrypted !== undefined) {
      setClauses.push('api_key_encrypted = ?');
      values.push(updates.apiKeyEncrypted);
    }
    if (updates.defaultModel !== undefined) {
      setClauses.push('default_model = ?');
      values.push(updates.defaultModel);
    }
    if (updates.enabled !== undefined) {
      setClauses.push('enabled = ?');
      values.push(updates.enabled ? 1 : 0);
    }

    setClauses.push('updated_at = CURRENT_TIMESTAMP');
    values.push(providerId);

    try {
      this.db.prepare(`UPDATE providers SET ${setClauses.join(', ')} WHERE provider_id = ?`).run(...values);
      return true;
    } catch {
      return false;
    }
  }

  public getProvider(providerId: string): ProviderRecord | null {
    const row = this.db.prepare('SELECT * FROM providers WHERE provider_id = ?').get(providerId) as any;
    if (!row) return null;

    return {
      id: row.id,
      providerId: row.provider_id,
      name: row.name,
      baseURL: row.base_url,
      apiKeyEncrypted: row.api_key_encrypted,
      defaultModel: row.default_model,
      enabled: Boolean(row.enabled),
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }

  public getAllProviders(): ProviderRecord[] {
    const rows = this.db.prepare('SELECT * FROM providers ORDER BY name').all() as any[];

    return rows.map(row => ({
      id: row.id,
      providerId: row.provider_id,
      name: row.name,
      baseURL: row.base_url,
      apiKeyEncrypted: row.api_key_encrypted,
      defaultModel: row.default_model,
      enabled: Boolean(row.enabled),
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));
  }

  public deleteProvider(providerId: string): boolean {
    try {
      this.db.prepare('DELETE FROM providers WHERE provider_id = ?').run(providerId);
      return true;
    } catch {
      return false;
    }
  }

  public addBackupRecord(backup: Omit<BackupRecord, 'id' | 'createdAt'>): number | null {
    try {
      const result = this.db.prepare(`
        INSERT INTO backups (filename, path, size, options)
        VALUES (?, ?, ?, ?)
      `).run(backup.filename, backup.path, backup.size, backup.options);
      return result.lastInsertRowid as number;
    } catch {
      return null;
    }
  }

  public getBackupHistory(limit: number = 10): BackupRecord[] {
    const rows = this.db.prepare('SELECT * FROM backups ORDER BY created_at DESC LIMIT ?').all(limit) as any[];

    return rows.map(row => ({
      id: row.id,
      filename: row.filename,
      path: row.path,
      size: row.size,
      options: row.options,
      createdAt: row.created_at,
    }));
  }

  public addHistory(action: string, details?: string): void {
    this.db.prepare('INSERT INTO history (action, details) VALUES (?, ?)').run(action, details || null);
  }

  public getHistory(limit: number = 50): HistoryRecord[] {
    const rows = this.db.prepare('SELECT * FROM history ORDER BY created_at DESC LIMIT ?').all(limit) as any[];

    return rows.map(row => ({
      id: row.id,
      action: row.action,
      details: row.details,
      createdAt: row.created_at,
    }));
  }

  public close(): void {
    this.db.close();
  }
}

let dbInstance: DatabaseManager | null = null;

export function getDatabase(): DatabaseManager {
  if (!dbInstance) {
    dbInstance = new DatabaseManager();
  }
  return dbInstance;
}
