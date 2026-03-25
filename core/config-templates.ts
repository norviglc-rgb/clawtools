import { recommendedConfig, defaultOpenClawConfig } from '../config/providers.js';
import { Configurator } from './configurator.js';

export interface ConfigTemplate {
  id: string;
  name: string;
  description: string;
  priority: 'minimal' | 'balanced' | 'performance' | 'custom';
  settings: {
    model: string;
    temperature: number;
    maxTokens: number;
    streaming: boolean;
    safety: {
      skipPaidModels: boolean;
      enableAuditLogging: boolean;
    };
    performance: {
      enableCaching: boolean;
      connectionTimeout: number;
      maxRetries: number;
    };
    network: {
      proxyEnabled: boolean;
      proxyUrl: string;
      noProxy: string;
    };
  };
}

export const templates: Record<string, ConfigTemplate> = {
  'minimal': {
    id: 'minimal',
    name: 'Minimal Setup',
    description: 'Basic configuration with free models only, no advanced features',
    priority: 'minimal',
    settings: {
      model: 'claude-haiku-4-5-20251001',
      temperature: 0.7,
      maxTokens: 4096,
      streaming: false,
      safety: {
        skipPaidModels: true,
        enableAuditLogging: false,
      },
      performance: {
        enableCaching: false,
        connectionTimeout: 15000,
        maxRetries: 2,
      },
      network: {
        proxyEnabled: false,
        proxyUrl: '',
        noProxy: 'localhost,127.0.0.1',
      },
    },
  },
  'balanced': {
    id: 'balanced',
    name: 'Balanced (Recommended)',
    description: 'Recommended settings with caching and paid model access',
    priority: 'balanced',
    settings: {
      model: 'claude-sonnet-4-6',
      temperature: 0.7,
      maxTokens: 8192,
      streaming: true,
      safety: {
        skipPaidModels: false,
        enableAuditLogging: false,
      },
      performance: {
        enableCaching: true,
        connectionTimeout: 30000,
        maxRetries: 3,
      },
      network: {
        proxyEnabled: false,
        proxyUrl: '',
        noProxy: 'localhost,127.0.0.1',
      },
    },
  },
  'performance': {
    id: 'performance',
    name: 'Performance',
    description: 'Optimized for speed with longer context and retries',
    priority: 'performance',
    settings: {
      model: 'claude-opus-4-6',
      temperature: 0.5,
      maxTokens: 32768,
      streaming: true,
      safety: {
        skipPaidModels: false,
        enableAuditLogging: true,
      },
      performance: {
        enableCaching: true,
        connectionTimeout: 60000,
        maxRetries: 5,
      },
      network: {
        proxyEnabled: false,
        proxyUrl: '',
        noProxy: 'localhost,127.0.0.1',
      },
    },
  },
};

export interface TemplateApplyResult {
  success: boolean;
  templateId?: string;
  error?: string;
}

export class ConfigTemplateManager {
  private configurator: Configurator;

  constructor(configurator?: Configurator) {
    this.configurator = configurator || new Configurator();
  }

  public getTemplate(templateId: string): ConfigTemplate | null {
    return templates[templateId] || null;
  }

  public getAllTemplates(): ConfigTemplate[] {
    return Object.values(templates);
  }

  public getTemplatesByPriority(priority: ConfigTemplate['priority']): ConfigTemplate[] {
    return this.getAllTemplates().filter(t => t.priority === priority);
  }

  public applyTemplate(templateId: string): TemplateApplyResult {
    const template = this.getTemplate(templateId);
    if (!template) {
      return { success: false, error: `Template '${templateId}' not found` };
    }

    try {
      const config = this.configurator.loadConfig() || this.buildDefaultConfig();

      config.agents = config.agents || {};
      config.agents.defaults = config.agents.defaults || {};
      config.agents.defaults.model = config.agents.defaults.model || {};
      config.agents.defaults.model.primary = `anthropic/${template.settings.model}`;

      if (!config.safety) config.safety = {};
      config.safety.skipPaidModels = template.settings.safety.skipPaidModels;
      config.safety.confirmBeforeExec = true;

      if (!config.performance) config.performance = {};
      config.performance.enableCaching = template.settings.performance.enableCaching;
      config.performance.connectionTimeout = template.settings.performance.connectionTimeout;
      config.performance.maxRetries = template.settings.performance.maxRetries;

      if (!config.network) config.network = {};
      config.network.proxyEnabled = template.settings.network.proxyEnabled;
      config.network.proxyUrl = template.settings.network.proxyUrl;
      config.network.noProxy = template.settings.network.noProxy;

      const success = this.configurator.saveConfig(config);
      if (!success) {
        return { success: false, error: 'Failed to save configuration' };
      }

      return { success: true, templateId };
    } catch (error) {
      return { success: false, error: String(error) };
    }
  }

  public applyRecommended(): TemplateApplyResult {
    return this.applyTemplate('balanced');
  }

  public getCurrentConfig(): Record<string, any> | null {
    return this.configurator.loadConfig();
  }

  public updateTemplateSetting(
    templateId: string,
    path: string,
    value: unknown
  ): TemplateApplyResult {
    const template = this.getTemplate(templateId);
    if (!template) {
      return { success: false, error: `Template '${templateId}' not found` };
    }

    const parts = path.split('.');
    let current: any = template.settings;

    for (let i = 0; i < parts.length - 1; i++) {
      if (current[parts[i]] === undefined) {
        current[parts[i]] = {};
      }
      current = current[parts[i]];
    }

    current[parts[parts.length - 1]] = value;
    return { success: true, templateId };
  }

  public validateTemplate(template: ConfigTemplate): string[] {
    const errors: string[] = [];

    if (!template.id) errors.push('Template ID is required');
    if (!template.name) errors.push('Template name is required');
    if (!template.settings) errors.push('Template settings are required');

    if (template.settings) {
      if (typeof template.settings.temperature !== 'number' ||
          template.settings.temperature < 0 ||
          template.settings.temperature > 2) {
        errors.push('Temperature must be between 0 and 2');
      }

      if (typeof template.settings.maxTokens !== 'number' ||
          template.settings.maxTokens < 1) {
        errors.push('Max tokens must be at least 1');
      }

      if (typeof template.settings.performance.connectionTimeout !== 'number' ||
          template.settings.performance.connectionTimeout < 1000) {
        errors.push('Connection timeout must be at least 1000ms');
      }

      if (typeof template.settings.performance.maxRetries !== 'number' ||
          template.settings.performance.maxRetries < 0) {
        errors.push('Max retries must be non-negative');
      }
    }

    return errors;
  }

  private buildDefaultConfig(): Record<string, any> {
    return JSON.parse(JSON.stringify(defaultOpenClawConfig));
  }

  public exportTemplate(templateId: string): string | null {
    const template = this.getTemplate(templateId);
    if (!template) return null;
    return JSON.stringify(template, null, 2);
  }

  public getRecommendedTemplateId(): string {
    return 'balanced';
  }
}

let templateManagerInstance: ConfigTemplateManager | null = null;

export function getTemplateManager(): ConfigTemplateManager {
  if (!templateManagerInstance) {
    templateManagerInstance = new ConfigTemplateManager();
  }
  return templateManagerInstance;
}
