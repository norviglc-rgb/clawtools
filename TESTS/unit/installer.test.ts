import { describe, it, expect } from 'vitest';
import {
  getOpenClawInstallCommand,
  getAvailableVersions,
  installNode,
  uninstallOpenClaw,
  type InstallChannel,
  type InstallMethod,
  type InstallOptions,
  type InstallResult
} from '../../core/installer';

describe('installer', () => {
  describe('getAvailableVersions', () => {
    it('should return an array', () => {
      const versions = getAvailableVersions();
      expect(Array.isArray(versions)).toBe(true);
    });

    it('should return version strings', () => {
      const versions = getAvailableVersions();
      versions.forEach(v => {
        expect(typeof v).toBe('string');
      });
    });

    it('should return at least one version', () => {
      const versions = getAvailableVersions();
      expect(versions.length).toBeGreaterThan(0);
    });
  });

  describe('getOpenClawInstallCommand', () => {
    it('should return a string', () => {
      const options: InstallOptions = {
        method: 'npm',
        channel: 'stable'
      };
      const cmd = getOpenClawInstallCommand(options);
      expect(typeof cmd).toBe('string');
    });

    it('should include npm for npm method', () => {
      const cmd = getOpenClawInstallCommand({ method: 'npm', channel: 'stable' });
      expect(cmd).toContain('npm');
    });

    it('should include script for script method', () => {
      const cmd = getOpenClawInstallCommand({ method: 'script', channel: 'stable' });
      expect(cmd).toContain('curl') || expect(cmd).toContain('wget');
    });

    it('should handle stable channel', () => {
      const cmd = getOpenClawInstallCommand({ method: 'npm', channel: 'stable' });
      expect(typeof cmd).toBe('string');
    });

    it('should handle beta channel', () => {
      const cmd = getOpenClawInstallCommand({ method: 'npm', channel: 'beta' });
      expect(typeof cmd).toBe('string');
    });

    it('should handle dev channel', () => {
      const cmd = getOpenClawInstallCommand({ method: 'npm', channel: 'dev' });
      expect(typeof cmd).toBe('string');
    });

    it('should handle version option', () => {
      const cmd = getOpenClawInstallCommand({ method: 'npm', channel: 'stable', version: '1.0.0' });
      expect(typeof cmd).toBe('string');
    });
  });

  describe('InstallOptions type', () => {
    it('should accept full options', () => {
      const options: InstallOptions = {
        method: 'npm',
        channel: 'stable',
        version: '1.0.0',
        global: true
      };
      expect(options.method).toBe('npm');
      expect(options.channel).toBe('stable');
      expect(options.version).toBe('1.0.0');
      expect(options.global).toBe(true);
    });

    it('should accept minimal options', () => {
      const options: InstallOptions = {
        method: 'npm',
        channel: 'stable'
      };
      expect(options.method).toBe('npm');
      expect(options.channel).toBe('stable');
    });

    it('should accept script method', () => {
      const options: InstallOptions = {
        method: 'script',
        channel: 'beta'
      };
      expect(options.method).toBe('script');
    });

    it('should accept docker method', () => {
      const options: InstallOptions = {
        method: 'docker',
        channel: 'dev'
      };
      expect(options.method).toBe('docker');
    });
  });

  describe('InstallResult type', () => {
    it('should accept success result', () => {
      const result: InstallResult = {
        success: true,
        message: 'Installed successfully',
        version: '1.0.0',
        path: '/usr/local/bin'
      };
      expect(result.success).toBe(true);
      expect(result.version).toBe('1.0.0');
      expect(result.path).toBe('/usr/local/bin');
    });

    it('should accept failure result', () => {
      const result: InstallResult = {
        success: false,
        message: 'Installation failed'
      };
      expect(result.success).toBe(false);
    });
  });

  describe('InstallChannel type', () => {
    it('should accept stable channel', () => {
      const channel: InstallChannel = 'stable';
      expect(channel).toBe('stable');
    });

    it('should accept beta channel', () => {
      const channel: InstallChannel = 'beta';
      expect(channel).toBe('beta');
    });

    it('should accept dev channel', () => {
      const channel: InstallChannel = 'dev';
      expect(channel).toBe('dev');
    });
  });

  describe('InstallMethod type', () => {
    it('should accept npm method', () => {
      const method: InstallMethod = 'npm';
      expect(method).toBe('npm');
    });

    it('should accept script method', () => {
      const method: InstallMethod = 'script';
      expect(method).toBe('script');
    });

    it('should accept docker method', () => {
      const method: InstallMethod = 'docker';
      expect(method).toBe('docker');
    });
  });

  describe('installNode', () => {
    it('should accept win32 platform', async () => {
      const result = await installNode('win32');
      expect(result).toHaveProperty('success');
      expect(result).toHaveProperty('message');
    });

    it('should accept linux platform', async () => {
      const result = await installNode('linux');
      expect(result).toHaveProperty('success');
      expect(result).toHaveProperty('message');
    });

    it('should accept darwin platform', async () => {
      const result = await installNode('darwin');
      expect(result).toHaveProperty('success');
      expect(result).toHaveProperty('message');
    });

    it('should reject unsupported platform', async () => {
      const result = await installNode('freebsd');
      expect(result.success).toBe(false);
    });
  });

  describe('uninstallOpenClaw', () => {
    it('should be a function', () => {
      expect(typeof uninstallOpenClaw).toBe('function');
    });
  });
});