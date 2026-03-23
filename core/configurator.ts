import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import * as crypto from 'crypto';

export interface ProviderConfig {
  id: string;
  name: string;
  baseURL?: string;
  apiKeyEnvVar?: string;
  models?: string[];
  defaultModel?: string;
}

export interface OpenClawConfig {
  agents?: {
    defaults?: {
      model?: {
        primary?: string;
      };
    };
  };
  providers?: Record<string, any>;
  channels?: Record<string, any>;
  plugins?: string[];
  skills?: string[];
  [key: string]: any;
}

const DEFAULT_CONFIG_DIRS: Record<string, string> = {
  win32: path.join(os.homedir(), '.openclaw'),
  linux: path.join(os.homedir(), '.openclaw'),
  darwin: path.join(os.homedir(), '.openclaw'),
};

const DEFAULT_CONFIG_FILES = ['config.json', 'config.js', 'settings.json'];

export class Configurator {
  private configDir: string;
  private configFile: string | null;
  private encryptionKey: Buffer | null = null;

  constructor(configDir?: string) {
    const platform = process.platform;
    this.configDir = configDir || DEFAULT_CONFIG_DIRS[platform] || path.join(os.homedir(), '.openclaw');
    this.configFile = this.findConfigFile();
  }

  private findConfigFile(): string | null {
    for (const file of DEFAULT_CONFIG_FILES) {
      const fullPath = path.join(this.configDir, file);
      if (fs.existsSync(fullPath)) {
        return fullPath;
      }
    }
    return null;
  }

  public getConfigDir(): string {
    return this.configDir;
  }

  public getConfigFile(): string | null {
    return this.configFile;
  }

  public loadConfig(): OpenClawConfig | null {
    if (!this.configFile) {
      return null;
    }

    try {
      const content = fs.readFileSync(this.configFile, 'utf8');
      if (this.configFile.endsWith('.js')) {
        const vm = require('vm');
        const module = { exports: {} };
        const script = new vm.Script(`module.exports = ${content}`);
        script.runInNewContext({ module, require, __dirname: this.configDir });
        return module.exports;
      }
      return JSON.parse(content);
    } catch (error) {
      console.error('Failed to load config:', error);
      return null;
    }
  }

  public saveConfig(config: OpenClawConfig): boolean {
    if (!this.configFile) {
      if (!fs.existsSync(this.configDir)) {
        fs.mkdirSync(this.configDir, { recursive: true });
      }
      this.configFile = path.join(this.configDir, 'config.json');
    }

    try {
      const content = JSON.stringify(config, null, 2);
      fs.writeFileSync(this.configFile, content, 'utf8');
      return true;
    } catch (error) {
      console.error('Failed to save config:', error);
      return false;
    }
  }

  public setEncryptionKey(key: string): void {
    this.encryptionKey = crypto.createHash('sha256').update(key).digest();
  }

  public encryptApiKey(apiKey: string): string {
    if (!this.encryptionKey) {
      throw new Error('Encryption key not set');
    }
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-cbc', this.encryptionKey, iv);
    let encrypted = cipher.update(apiKey, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return iv.toString('hex') + ':' + encrypted;
  }

  public decryptApiKey(encrypted: string): string {
    if (!this.encryptionKey) {
      throw new Error('Encryption key not set');
    }
    const parts = encrypted.split(':');
    const iv = Buffer.from(parts[0], 'hex');
    const encryptedText = parts[1];
    const decipher = crypto.createDecipheriv('aes-256-cbc', this.encryptionKey, iv);
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  }

  public getProviderFromConfig(providerId: string): any {
    const config = this.loadConfig();
    if (!config || !config.providers) {
      return null;
    }
    return config.providers[providerId];
  }

  public setProviderConfig(providerId: string, providerConfig: any): boolean {
    const config = this.loadConfig() || {};
    if (!config.providers) {
      config.providers = {};
    }
    config.providers[providerId] = providerConfig;
    return this.saveConfig(config);
  }

  public removeProviderConfig(providerId: string): boolean {
    const config = this.loadConfig();
    if (!config || !config.providers) {
      return false;
    }
    delete config.providers[providerId];
    return this.saveConfig(config);
  }

  public setDefaultModel(providerId: string, model: string): boolean {
    const config = this.loadConfig() || {};
    if (!config.agents) {
      config.agents = {};
    }
    if (!config.agents.defaults) {
      config.agents.defaults = {};
    }
    if (!config.agents.defaults.model) {
      config.agents.defaults.model = {};
    }
    config.agents.defaults.model.primary = `${providerId}/${model}`;
    return this.saveConfig(config);
  }

  public backupConfig(backupPath: string): boolean {
    if (!this.configFile || !fs.existsSync(this.configFile)) {
      return false;
    }

    try {
      const content = fs.readFileSync(this.configFile, 'utf8');
      const config = JSON.parse(content);
      const backup = {
        timestamp: new Date().toISOString(),
        version: '1.0',
        config,
        files: [] as { name: string; content: string }[],
      };

      const configDir = this.configDir;
      if (fs.existsSync(configDir)) {
        const files = fs.readdirSync(configDir);
        for (const file of files) {
          if (file === path.basename(this.configFile!)) continue;
          const filePath = path.join(configDir, file);
          const stat = fs.statSync(filePath);
          if (stat.isFile() && stat.size < 1024 * 1024) {
            backup.files.push({
              name: file,
              content: fs.readFileSync(filePath, 'utf8'),
            });
          }
        }
      }

      fs.writeFileSync(backupPath, JSON.stringify(backup, null, 2), 'utf8');
      return true;
    } catch (error) {
      console.error('Backup failed:', error);
      return false;
    }
  }

  public restoreConfig(backupPath: string): boolean {
    try {
      const content = fs.readFileSync(backupPath, 'utf8');
      const backup = JSON.parse(content);

      if (!backup.config) {
        return false;
      }

      if (!fs.existsSync(this.configDir)) {
        fs.mkdirSync(this.configDir, { recursive: true });
      }

      const configFile = path.join(this.configDir, 'config.json');
      fs.writeFileSync(configFile, JSON.stringify(backup.config, null, 2), 'utf8');
      this.configFile = configFile;

      if (backup.files && Array.isArray(backup.files)) {
        for (const file of backup.files) {
          const filePath = path.join(this.configDir, file.name);
          fs.writeFileSync(filePath, file.content, 'utf8');
        }
      }

      return true;
    } catch (error) {
      console.error('Restore failed:', error);
      return false;
    }
  }
}

export const presetProviders: ProviderConfig[] = [
  {
    id: 'anthropic',
    name: 'Anthropic (Claude)',
    models: ['claude-opus-4-6', 'claude-sonnet-4-6', 'claude-haiku-4-5-20251001'],
    defaultModel: 'claude-sonnet-4-6',
  },
  {
    id: 'openai',
    name: 'OpenAI',
    baseURL: 'https://api.openai.com/v1',
    models: ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo'],
    defaultModel: 'gpt-4o',
  },
  {
    id: 'minimax',
    name: 'MiniMax',
    baseURL: 'https://api.minimax.chat/v1',
    models: ['MiniMax-Text-01', 'abab6.5s-chat'],
    defaultModel: 'MiniMax-Text-01',
  },
  {
    id: 'zhipu',
    name: 'Zhipu (GLM)',
    baseURL: 'https://open.bigmodel.cn/api/paas/v4',
    models: ['glm-4', 'glm-4-flash', 'glm-4-plus'],
    defaultModel: 'glm-4-flash',
  },
];
