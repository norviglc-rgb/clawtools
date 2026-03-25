import React, { useState, useEffect } from 'react';
import { Box, Text } from 'ink';
import { Configurator, presetProviders } from '../../core/configurator';
import { getDatabase, ProviderRecord } from '../../db/index';

type ConfigStep = 'menu' | 'select-provider' | 'enter-apikey' | 'done';

export function ConfigScreen() {
  const [step, setStep] = useState<ConfigStep>('menu');
  const [selectedProvider, setSelectedProvider] = useState<string>('');
  const [apiKey, setApiKey] = useState('');
  const [message, setMessage] = useState('');
  const configurator = new Configurator();
  const db = getDatabase();

  const savedProviders = db.getAllProviders();
  const allProviders = [...presetProviders.map(p => p.id), ...savedProviders.map(p => p.providerId)];
  const uniqueProviders = [...new Set(allProviders)];

  const handleSelectProvider = (providerId: string) => {
    setSelectedProvider(providerId);
    setStep('enter-apikey');
  };

  const handleSaveApiKey = () => {
    if (!apiKey.trim()) {
      setMessage('API key cannot be empty');
      return;
    }

    const provider = presetProviders.find(p => p.id === selectedProvider);
    if (provider) {
      const encrypted = configurator.encryptApiKey(apiKey);
      db.addProvider({
        providerId: provider.id,
        name: provider.name,
        baseURL: provider.baseURL || null,
        apiKeyEncrypted: encrypted,
        defaultModel: provider.defaultModel || null,
        enabled: true,
      });
      setMessage(`API key saved for ${provider.name}`);
    } else {
      db.addProvider({
        providerId: selectedProvider,
        name: selectedProvider,
        baseURL: null,
        apiKeyEncrypted: configurator.encryptApiKey(apiKey),
        defaultModel: null,
        enabled: true,
      });
      setMessage(`API key saved for ${selectedProvider}`);
    }

    setApiKey('');
    setStep('done');
  };

  useEffect(() => {
    const handler = (data: Buffer) => {
      const key = data.toString();

      if (step === 'menu') {
        const num = parseInt(key);
        if (num >= 1 && num <= uniqueProviders.length) {
          handleSelectProvider(uniqueProviders[num - 1]);
        } else if (key === 'q' || key === '\x1b') {
          process.exit(0);
        }
      } else if (step === 'enter-apikey') {
        if (key === '\r' || key === '\n') {
          handleSaveApiKey();
        } else if (key === '\x7f') {
          setApiKey(prev => prev.slice(0, -1));
        } else if (key.length === 1) {
          setApiKey(prev => prev + key);
        }
      } else if (step === 'done') {
        if (key === '\r' || key === '\n' || key === '\x1b') {
          setStep('menu');
        }
      }
    };

    process.stdin.setRawMode(true);
    process.stdin.on('data', handler);

    return () => {
      process.stdin.setRawMode(false);
      process.stdin.removeAllListeners('data');
    };
  }, [step, selectedProvider, apiKey]);

  return (
    <Box flexDirection="column" padding={1}>
      <Text bold>Provider Configuration</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>

      {step === 'menu' && (
        <>
          <Box marginBottom={1}>
            <Text>Select a provider to configure:</Text>
          </Box>
          {uniqueProviders.map((providerId, index) => {
            const preset = presetProviders.find(p => p.id === providerId);
            const saved = savedProviders.find(p => p.providerId === providerId);

            return (
              <Box key={providerId} marginBottom={1}>
                <Box width={3}>
                  <Text color="cyan">{index + 1}</Text>
                </Box>
                <Text bold>{preset?.name || providerId}</Text>
                {saved && <Text dimColor> (configured)</Text>}
              </Box>
            );
          })}
          <Box marginTop={1}>
            <Text dimColor>Press [1-{uniqueProviders.length}] to select, [q] to quit</Text>
          </Box>
        </>
      )}

      {step === 'enter-apikey' && (
        <>
          <Text>Configuring: </Text>
          <Text bold color="cyan">{selectedProvider}</Text>
          <Box marginY={1}>
            <Text>Enter API Key (press Enter to save):</Text>
          </Box>
          <Box>
            <Text>{apiKey.replace(/./g, '*')}</Text>
            <Text dimColor> █</Text>
          </Box>
        </>
      )}

      {step === 'done' && (
        <>
          <Text color="green">{message}</Text>
          <Box marginTop={1}>
            <Text dimColor>Press any key to continue</Text>
          </Box>
        </>
      )}
    </Box>
  );
}
