import { describe, it, expect } from 'vitest';
import {
  providerPresets,
  recommendedConfig,
  defaultOpenClawConfig,
  type ProviderPreset
} from '../../config/providers';

describe('providers', () => {
  describe('providerPresets', () => {
    it('should be a Record with entries', () => {
      expect(typeof providerPresets).toBe('object');
      expect(Object.keys(providerPresets).length).toBeGreaterThan(0);
    });

    it('each preset should have required fields', () => {
      Object.values(providerPresets).forEach((preset: ProviderPreset) => {
        expect(preset.id).toBeDefined();
        expect(preset.name).toBeDefined();
        expect(preset.providerType).toBeDefined();
      });
    });

    it('should include common providers', () => {
      expect(providerPresets).toHaveProperty('anthropic');
      expect(providerPresets).toHaveProperty('openai');
      expect(providerPresets).toHaveProperty('minimax');
      expect(providerPresets).toHaveProperty('zhipu');
    });

    it('should have valid auth types', () => {
      Object.values(providerPresets).forEach((preset: ProviderPreset) => {
        expect(['bearer', 'apikey', 'none']).toContain(preset.authType);
      });
    });
  });

  describe('recommendedConfig', () => {
    it('should be defined', () => {
      expect(recommendedConfig).toBeDefined();
    });

    it('should have model setting', () => {
      expect(recommendedConfig).toHaveProperty('model');
    });

    it('should have temperature setting', () => {
      expect(recommendedConfig).toHaveProperty('temperature');
    });

    it('should have safety settings', () => {
      expect(recommendedConfig).toHaveProperty('safety');
      expect(recommendedConfig.safety).toHaveProperty('skipPaidModels');
    });

    it('should have performance settings', () => {
      expect(recommendedConfig).toHaveProperty('performance');
      expect(recommendedConfig.performance).toHaveProperty('enableCaching');
    });

    it('should have network settings', () => {
      expect(recommendedConfig).toHaveProperty('network');
      expect(recommendedConfig.network).toHaveProperty('proxyEnabled');
    });
  });

  describe('defaultOpenClawConfig', () => {
    it('should be defined', () => {
      expect(defaultOpenClawConfig).toBeDefined();
    });

    it('should have agents section', () => {
      expect(defaultOpenClawConfig).toHaveProperty('agents');
    });

    it('should have gateway section', () => {
      expect(defaultOpenClawConfig).toHaveProperty('gateway');
      expect(defaultOpenClawConfig.gateway).toHaveProperty('port');
    });

    it('should have logging section', () => {
      expect(defaultOpenClawConfig).toHaveProperty('logging');
      expect(defaultOpenClawConfig.logging).toHaveProperty('level');
    });

    it('should have safety section', () => {
      expect(defaultOpenClawConfig).toHaveProperty('safety');
    });
  });
});