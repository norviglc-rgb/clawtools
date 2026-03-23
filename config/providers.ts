export interface ProviderPreset {
  id: string;
  name: string;
  providerType: 'openai-compatible' | 'anthropic' | 'custom';
  baseURL?: string;
  apiKeyPlaceholder?: string;
  defaultModels: string[];
  models: string[];
  authType: 'bearer' | 'apikey' | 'none';
  features?: {
    streaming?: boolean;
    vision?: boolean;
    functionCalling?: boolean;
  };
}

export const providerPresets: Record<string, ProviderPreset> = {
  'anthropic': {
    id: 'anthropic',
    name: 'Anthropic (Claude)',
    providerType: 'anthropic',
    apiKeyPlaceholder: 'sk-ant-...',
    defaultModels: ['claude-opus-4-6', 'claude-sonnet-4-6', 'claude-haiku-4-5-20251001'],
    models: [
      'claude-opus-4-6',
      'claude-sonnet-4-6',
      'claude-haiku-4-5-20251001',
      'claude-3-5-sonnet-latest',
      'claude-3-5-haiku-latest',
    ],
    authType: 'bearer',
    features: {
      streaming: true,
      vision: true,
      functionCalling: true,
    },
  },
  'openai': {
    id: 'openai',
    name: 'OpenAI',
    providerType: 'openai-compatible',
    baseURL: 'https://api.openai.com/v1',
    apiKeyPlaceholder: 'sk-...',
    defaultModels: ['gpt-4o', 'gpt-4o-mini'],
    models: [
      'gpt-4o',
      'gpt-4o-mini',
      'gpt-4-turbo',
      'gpt-3.5-turbo',
    ],
    authType: 'bearer',
    features: {
      streaming: true,
      vision: true,
      functionCalling: true,
    },
  },
  'minimax': {
    id: 'minimax',
    name: 'MiniMax',
    providerType: 'openai-compatible',
    baseURL: 'https://api.minimax.chat/v1',
    apiKeyPlaceholder: 'eyJ...',
    defaultModels: ['MiniMax-Text-01', 'abab6.5s-chat'],
    models: [
      'MiniMax-Text-01',
      'abab6.5s-chat',
      'abab5.5s-chat',
    ],
    authType: 'bearer',
    features: {
      streaming: true,
      vision: false,
      functionCalling: true,
    },
  },
  'zhipu': {
    id: 'zhipu',
    name: 'Zhipu (GLM)',
    providerType: 'openai-compatible',
    baseURL: 'https://open.bigmodel.cn/api/paas/v4',
    apiKeyPlaceholder: 'glm-...',
    defaultModels: ['glm-4-flash', 'glm-4'],
    models: [
      'glm-4-flash',
      'glm-4',
      'glm-4-plus',
      'glm-4v-flash',
    ],
    authType: 'bearer',
    features: {
      streaming: true,
      vision: true,
      functionCalling: true,
    },
  },
  'openrouter': {
    id: 'openrouter',
    name: 'OpenRouter',
    providerType: 'openai-compatible',
    baseURL: 'https://openrouter.ai/api/v1',
    apiKeyPlaceholder: 'sk-or-...',
    defaultModels: ['anthropic/claude-3.5-sonnet'],
    models: [
      'anthropic/claude-3.5-sonnet',
      'openai/gpt-4o',
      'google/gemini-pro-1.5',
    ],
    authType: 'bearer',
    features: {
      streaming: true,
      vision: true,
      functionCalling: true,
    },
  },
  'ollama': {
    id: 'ollama',
    name: 'Ollama (Local)',
    providerType: 'openai-compatible',
    baseURL: 'http://localhost:11434/v1',
    apiKeyPlaceholder: 'ollama',
    defaultModels: ['llama3.2', 'codellama'],
    models: [
      'llama3.2',
      'llama3.1',
      'codellama',
      'mistral',
      'phi3',
    ],
    authType: 'none',
    features: {
      streaming: true,
      vision: false,
      functionCalling: false,
    },
  },
};

export const recommendedConfig = {
  model: 'claude-sonnet-4-6',
  temperature: 0.7,
  maxTokens: 8192,
  streaming: true,
  safety: {
    skipPaidModels: true,
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
};

export const defaultOpenClawConfig = {
  agents: {
    defaults: {
      model: {
        primary: 'anthropic/claude-sonnet-4-6',
      },
    },
  },
  gateway: {
    port: 18789,
    host: '127.0.0.1',
  },
  logging: {
    level: 'info',
    format: 'pretty',
  },
  safety: {
    skipPaidModels: true,
    confirmBeforeExec: true,
  },
};
