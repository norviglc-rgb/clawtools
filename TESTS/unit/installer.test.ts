import { describe, it, expect } from 'vitest';
import {
  getOpenClawInstallCommand,
  getAvailableVersions,
  type InstallChannel,
  type InstallMethod,
  type InstallOptions
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

    it('should handle different channels', () => {
      const stableCmd = getOpenClawInstallCommand({ method: 'npm', channel: 'stable' });
      const betaCmd = getOpenClawInstallCommand({ method: 'npm', channel: 'beta' });
      expect(typeof stableCmd).toBe('string');
      expect(typeof betaCmd).toBe('string');
    });
  });

  describe('InstallOptions type', () => {
    it('should accept valid install options', () => {
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
});