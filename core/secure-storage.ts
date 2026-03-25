import * as crypto from 'crypto';
import * as os from 'os';
import * as path from 'path';
import * as fs from 'fs';
import { fileURLToPath } from 'url';
import { getDatabase, ProviderRecord } from '../db/index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export interface StoredProvider {
  providerId: string;
  name: string;
  baseURL: string | null;
  apiKey: string | null;
  defaultModel: string | null;
  enabled: boolean;
}

export interface MasterPasswordResult {
  success: boolean;
  isNew: boolean;
  error?: string;
}

function getKeychainPath(): string {
  const keychainDir = path.join(os.homedir(), '.clawtools');
  return path.join(keychainDir, '.masterkey');
}

function deriveKey(masterPassword: string): Buffer {
  return crypto.createHash('sha256').update(masterPassword).digest();
}

export class SecureKeyStorage {
  private encryptionKey: Buffer | null = null;
  private db = getDatabase();

  public hasMasterPassword(): boolean {
    const keychainPath = getKeychainPath();
    return fs.existsSync(keychainPath);
  }

  public setupMasterPassword(masterPassword: string): MasterPasswordResult {
    if (this.hasMasterPassword()) {
      return { success: false, isNew: false, error: 'Master password already exists' };
    }

    if (!masterPassword || masterPassword.length < 8) {
      return { success: false, isNew: true, error: 'Master password must be at least 8 characters' };
    }

    try {
      const keychainDir = path.join(os.homedir(), '.clawtools');
      if (!fs.existsSync(keychainDir)) {
        fs.mkdirSync(keychainDir, { recursive: true });
      }

      const salt = crypto.randomBytes(32);
      const verifyToken = this.deriveVerifyToken(masterPassword, salt);

      const keychainContent = {
        salt: salt.toString('hex'),
        verifyToken,
        createdAt: new Date().toISOString(),
      };

      fs.writeFileSync(getKeychainPath(), JSON.stringify(keychainContent), 'utf8');

      this.encryptionKey = deriveKey(masterPassword);
      this.db.updateAppConfig({ encryptionEnabled: true });

      return { success: true, isNew: true };
    } catch (error) {
      return { success: false, isNew: true, error: String(error) };
    }
  }

  public unlock(masterPassword: string): MasterPasswordResult {
    const keychainPath = getKeychainPath();

    if (!fs.existsSync(keychainPath)) {
      return { success: false, isNew: false, error: 'No master password found' };
    }

    try {
      const content = fs.readFileSync(keychainPath, 'utf8');
      const keychain = JSON.parse(content);

      const salt = Buffer.from(keychain.salt, 'hex');
      const verifyToken = this.deriveVerifyToken(masterPassword, salt);

      if (verifyToken !== keychain.verifyToken) {
        return { success: false, isNew: false, error: 'Invalid master password' };
      }

      this.encryptionKey = deriveKey(masterPassword);
      return { success: true, isNew: false };
    } catch (error) {
      return { success: false, isNew: false, error: String(error) };
    }
  }

  private deriveVerifyToken(masterPassword: string, salt: Buffer): string {
    const verifyKey = crypto.pbkdf2Sync(masterPassword, salt, 100000, 32, 'sha256');
    return verifyKey.toString('hex');
  }

  public isUnlocked(): boolean {
    return this.encryptionKey !== null;
  }

  public lock(): void {
    this.encryptionKey = null;
  }

  private encrypt(plaintext: string): string {
    if (!this.encryptionKey) {
      throw new Error('Storage is locked');
    }
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-cbc', this.encryptionKey, iv);
    let encrypted = cipher.update(plaintext, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return iv.toString('hex') + ':' + encrypted;
  }

  private decrypt(encrypted: string): string {
    if (!this.encryptionKey) {
      throw new Error('Storage is locked');
    }
    const parts = encrypted.split(':');
    if (parts.length !== 2) {
      throw new Error('Invalid encrypted data format');
    }
    const iv = Buffer.from(parts[0], 'hex');
    const encryptedText = parts[1];
    const decipher = crypto.createDecipheriv('aes-256-cbc', this.encryptionKey, iv);
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  }

  public saveApiKey(providerId: string, name: string, apiKey: string, baseURL?: string, defaultModel?: string): boolean {
    if (!this.encryptionKey) {
      throw new Error('Storage is locked');
    }

    const encrypted = this.encrypt(apiKey);
    const existing = this.db.getProvider(providerId);

    if (existing) {
      return this.db.updateProvider(providerId, {
        name,
        baseURL: baseURL || null,
        apiKeyEncrypted: encrypted,
        defaultModel: defaultModel || null,
      });
    }

    return this.db.addProvider({
      providerId,
      name,
      baseURL: baseURL || null,
      apiKeyEncrypted: encrypted,
      defaultModel: defaultModel || null,
      enabled: true,
    }) !== null;
  }

  public getApiKey(providerId: string): string | null {
    if (!this.encryptionKey) {
      throw new Error('Storage is locked');
    }

    const record = this.db.getProvider(providerId);
    if (!record || !record.apiKeyEncrypted) {
      return null;
    }

    try {
      return this.decrypt(record.apiKeyEncrypted);
    } catch {
      return null;
    }
  }

  public getProvider(providerId: string): StoredProvider | null {
    const record = this.db.getProvider(providerId);
    if (!record) {
      return null;
    }

    return {
      providerId: record.providerId,
      name: record.name,
      baseURL: record.baseURL,
      apiKey: record.apiKeyEncrypted ? this.decrypt(record.apiKeyEncrypted) : null,
      defaultModel: record.defaultModel,
      enabled: record.enabled,
    };
  }

  public getAllProviders(): StoredProvider[] {
    const records = this.db.getAllProviders();
    return records.map(record => ({
      providerId: record.providerId,
      name: record.name,
      baseURL: record.baseURL,
      apiKey: record.apiKeyEncrypted ? this.decrypt(record.apiKeyEncrypted) : null,
      defaultModel: record.defaultModel,
      enabled: record.enabled,
    }));
  }

  public deleteApiKey(providerId: string): boolean {
    return this.db.deleteProvider(providerId);
  }

  public updateProvider(providerId: string, updates: Partial<Omit<StoredProvider, 'providerId' | 'apiKey'>>): boolean {
    const record = this.db.getProvider(providerId);
    if (!record) {
      return false;
    }

    const dbUpdates: Partial<ProviderRecord> = {};

    if (updates.name !== undefined) {
      dbUpdates.name = updates.name;
    }
    if (updates.baseURL !== undefined) {
      dbUpdates.baseURL = updates.baseURL;
    }
    if (updates.defaultModel !== undefined) {
      dbUpdates.defaultModel = updates.defaultModel;
    }
    if (updates.enabled !== undefined) {
      dbUpdates.enabled = updates.enabled;
    }

    if (Object.keys(dbUpdates).length === 0) {
      return true;
    }

    return this.db.updateProvider(providerId, dbUpdates);
  }

  public changeMasterPassword(currentPassword: string, newPassword: string): MasterPasswordResult {
    const unlockResult = this.unlock(currentPassword);
    if (!unlockResult.success) {
      return { success: false, isNew: false, error: 'Current password is incorrect' };
    }

    if (!newPassword || newPassword.length < 8) {
      this.lock();
      return { success: false, isNew: false, error: 'New password must be at least 8 characters' };
    }

    try {
      const records = this.db.getAllProviders();
      const decryptedKeys: Map<string, string> = new Map();

      for (const record of records) {
        if (record.apiKeyEncrypted) {
          decryptedKeys.set(record.providerId, this.decrypt(record.apiKeyEncrypted));
        }
      }

      const salt = crypto.randomBytes(32);
      const verifyToken = this.deriveVerifyToken(newPassword, salt);

      const keychainContent = {
        salt: salt.toString('hex'),
        verifyToken,
        createdAt: new Date().toISOString(),
      };

      fs.writeFileSync(getKeychainPath(), JSON.stringify(keychainContent), 'utf8');

      this.encryptionKey = deriveKey(newPassword);

      for (const [providerId, apiKey] of decryptedKeys) {
        const encrypted = this.encrypt(apiKey);
        this.db.updateProvider(providerId, { apiKeyEncrypted: encrypted });
      }

      return { success: true, isNew: false };
    } catch (error) {
      return { success: false, isNew: false, error: String(error) };
    }
  }
}

let secureStorageInstance: SecureKeyStorage | null = null;

export function getSecureStorage(): SecureKeyStorage {
  if (!secureStorageInstance) {
    secureStorageInstance = new SecureKeyStorage();
  }
  return secureStorageInstance;
}
