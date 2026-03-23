import { describe, it, expect, beforeEach } from 'vitest';
import { Configurator, presetProviders } from '../../core/configurator';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

describe('Configurator', () => {
  const testDir = path.join(os.tmpdir(), 'clawtools-config-test-' + Date.now());
  let configurator: Configurator;

  beforeEach(() => {
    if (!fs.existsSync(testDir)) {
      fs.mkdirSync(testDir, { recursive: true });
    }
    configurator = new Configurator(testDir);
  });

  describe('constructor', () => {
    it('should create configurator with custom config dir', () => {
      expect(configurator.getConfigDir()).toBe(testDir);
    });
  });

  describe('getConfigFile', () => {
    it('should return null when no config file exists', () => {
      expect(configurator.getConfigFile()).toBeNull();
    });
  });

  describe('loadConfig', () => {
    it('should return null when no config file exists', () => {
      expect(configurator.loadConfig()).toBeNull();
    });
  });

  describe('saveConfig', () => {
    it('should save config to file', () => {
      const config = {
        agents: {
          defaults: {
            model: {
              primary: 'anthropic/claude-sonnet-4-6'
            }
          }
        },
        plugins: ['plugin1'],
        skills: ['skill1']
      };

      const result = configurator.saveConfig(config);
      expect(result).toBe(true);
      expect(configurator.getConfigFile()).toBeDefined();
    });

    it('should load saved config', () => {
      const config = {
        agents: {
          defaults: {
            model: {
              primary: 'openai/gpt-4o'
            }
          }
        }
      };

      configurator.saveConfig(config);
      const loaded = configurator.loadConfig();

      expect(loaded).toBeDefined();
      expect(loaded?.agents?.defaults?.model?.primary).toBe('openai/gpt-4o');
    });
  });

  describe('encryption', () => {
    it('should encrypt and decrypt API key', () => {
      configurator.setEncryptionKey('test-encryption-key');

      const originalKey = 'sk-test-api-key-12345';
      const encrypted = configurator.encryptApiKey(originalKey);
      const decrypted = configurator.decryptApiKey(encrypted);

      expect(encrypted).not.toBe(originalKey);
      expect(decrypted).toBe(originalKey);
    });

    it('should throw when encrypting without key', () => {
      const newConfigurator = new Configurator();
      expect(() => newConfigurator.encryptApiKey('test')).toThrow('Encryption key not set');
    });

    it('should throw when decrypting without key', () => {
      const newConfigurator = new Configurator();
      expect(() => newConfigurator.decryptApiKey('abc:def')).toThrow('Encryption key not set');
    });
  });

  describe('provider config', () => {
    it('should set and get provider config', () => {
      const providerConfig = {
        id: 'test-provider',
        name: 'Test Provider',
        baseURL: 'https://test.com',
        models: ['model1', 'model2'],
        defaultModel: 'model1'
      };

      const result = configurator.setProviderConfig('test-provider', providerConfig);
      expect(result).toBe(true);

      const retrieved = configurator.getProviderFromConfig('test-provider');
      expect(retrieved).toEqual(providerConfig);
    });

    it('should return undefined for non-existent provider', () => {
      expect(configurator.getProviderFromConfig('non-existent')).toBeUndefined();
    });

    it('should remove provider config', () => {
      configurator.setProviderConfig('to-remove', { id: 'to-remove' });
      const result = configurator.removeProviderConfig('to-remove');
      expect(result).toBe(true);
      expect(configurator.getProviderFromConfig('to-remove')).toBeUndefined();
    });
  });

  describe('default model', () => {
    it('should set default model', () => {
      const result = configurator.setDefaultModel('openai', 'gpt-4o');
      expect(result).toBe(true);

      const config = configurator.loadConfig();
      expect(config?.agents?.defaults?.model?.primary).toBe('openai/gpt-4o');
    });
  });

  describe('backup and restore', () => {
    it('should backup config', () => {
      const config = {
        agents: { defaults: { model: { primary: 'test/model' } } }
      };
      configurator.saveConfig(config);

      const backupPath = path.join(testDir, 'backup.json');
      const result = configurator.backupConfig(backupPath);

      expect(result).toBe(true);
      expect(fs.existsSync(backupPath)).toBe(true);
    });

    it('should restore config from backup', () => {
      const config = {
        agents: { defaults: { model: { primary: 'original/model' } } }
      };
      configurator.saveConfig(config);

      const backupPath = path.join(testDir, 'restore-backup.json');
      configurator.backupConfig(backupPath);

      const newConfig = {
        agents: { defaults: { model: { primary: 'new/model' } } }
      };
      configurator.saveConfig(newConfig);

      const restoreResult = configurator.restoreConfig(backupPath);
      expect(restoreResult).toBe(true);

      const restored = configurator.loadConfig();
      expect(restored?.agents?.defaults?.model?.primary).toBe('original/model');
    });
  });
});

describe('presetProviders', () => {
  it('should have required providers', () => {
    expect(presetProviders.length).toBeGreaterThan(0);
  });

  it('should have anthropic provider', () => {
    const anthropic = presetProviders.find(p => p.id === 'anthropic');
    expect(anthropic).toBeDefined();
    expect(anthropic?.name).toBe('Anthropic (Claude)');
  });

  it('should have openai provider', () => {
    const openai = presetProviders.find(p => p.id === 'openai');
    expect(openai).toBeDefined();
    expect(openai?.baseURL).toBe('https://api.openai.com/v1');
  });

  it('should have minimax provider', () => {
    const minimax = presetProviders.find(p => p.id === 'minimax');
    expect(minimax).toBeDefined();
    expect(minimax?.baseURL).toBe('https://api.minimax.chat/v1');
  });

  it('should have zhipu provider', () => {
    const zhipu = presetProviders.find(p => p.id === 'zhipu');
    expect(zhipu).toBeDefined();
    expect(zhipu?.baseURL).toBe('https://open.bigmodel.cn/api/paas/v4');
  });
});