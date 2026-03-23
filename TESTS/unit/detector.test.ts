import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import * as detector from '../../core/detector';

// Mock child_process
vi.mock('child_process', () => ({
  execSync: vi.fn(),
  exec: vi.fn()
}));

vi.mock('node-fetch', () => ({
  default: vi.fn()
}));

describe('detector module', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('detectSystem', () => {
    it('should detect system information', () => {
      const result = detector.detectSystem();
      expect(result).toBeDefined();
      expect(result.platform).toMatch(/^(windows|linux|darwin|wsl)$/);
      expect(result.arch).toBeDefined();
      expect(result.homeDir).toBeDefined();
      expect(result.node).toBeDefined();
    });
  });

  describe('checkFirewall', () => {
    it.skip('should return firewall status - requires real system commands', async () => {
      const result = await detector.checkFirewall();
      expect(result).toBeDefined();
      expect(typeof result.enabled).toBe('boolean');
      expect(Array.isArray(result.ports)).toBe(true);
    });
  });

  describe('checkPublicIP', () => {
    it('should return public IP or null', async () => {
      const result = await detector.checkPublicIP();
      expect(result === null || typeof result === 'string').toBe(true);
    });
  });

  describe('detectPorts', () => {
    it('should detect if port is in use', async () => {
      const result = await detector.detectPorts(9999);
      expect(typeof result).toBe('boolean');
    });
  });
});

describe('SystemInfo types', () => {
  it('should have correct structure', () => {
    const info: detector.SystemInfo = {
      platform: 'windows',
      arch: 'x64',
      homeDir: '/home/user',
      node: {
        installed: true,
        version: '20.0.0',
        path: '/usr/bin/node',
        meetsRequirement: true
      },
      openclaw: {
        installed: false,
        version: null,
        path: null,
        configDir: null,
        configFile: null
      }
    };

    expect(info.platform).toBe('windows');
    expect(info.node.meetsRequirement).toBe(true);
    expect(info.openclaw.installed).toBe(false);
  });
});