import React, { useState } from 'react';
import { Box, Text } from 'ink';
import { SystemInfo } from '../../core/detector';
import { installOpenClaw, getAvailableVersions, InstallChannel } from '../../core/installer';

type InstallStep = 'select' | 'installing' | 'done';

export function InstallScreen({ systemInfo }: { systemInfo: SystemInfo }) {
  const [step, setStep] = useState<InstallStep>('select');
  const [selectedChannel, setSelectedChannel] = useState<InstallChannel>('stable');
  const [message, setMessage] = useState('');

  const channels: { id: InstallChannel; label: string; desc: string }[] = [
    { id: 'stable', label: 'Stable', desc: 'Latest stable release (recommended)' },
    { id: 'beta', label: 'Beta', desc: 'Pre-release with new features' },
    { id: 'dev', label: 'Dev', desc: 'Development build (unstable)' },
  ];

  const handleInstall = async () => {
    setStep('installing');
    setMessage(`Installing OpenClaw (${selectedChannel})...`);

    const result = await installOpenClaw({
      method: 'npm',
      channel: selectedChannel,
    });

    setMessage(result.message);
    setStep('done');
  };

  const handleKeypress = (data: Buffer, key: string) => {
    if (step !== 'select') return;

    if (key === '1') setSelectedChannel('stable');
    else if (key === '2') setSelectedChannel('beta');
    else if (key === '3') setSelectedChannel('dev');
    else if (key === '\r' || key === '\n') handleInstall();
  };

  React.useEffect(() => {
    const handler = (data: Buffer) => {
      const key = data.toString();
      handleKeypress(data, key);
    };

    process.stdin.setRawMode(true);
    process.stdin.on('data', handler);

    return () => {
      process.stdin.setRawMode(false);
      process.stdin.removeAllListeners('data');
    };
  }, [step, selectedChannel]);

  return (
    <Box flexDirection="column" padding={1}>
      <Text bold>OpenClaw Installation</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>

      {step === 'select' && (
        <>
          <Box marginBottom={1}>
            <Text>Select version channel:</Text>
          </Box>
          {channels.map((ch) => (
            <Box key={ch.id} marginBottom={1}>
              <Box width={3}>
                <Text color={selectedChannel === ch.id ? 'cyan' : undefined}>
                  [{selectedChannel === ch.id ? 'x' : ' '}]
                </Text>
              </Box>
              <Text bold color={selectedChannel === ch.id ? 'cyan' : undefined}>
                {ch.id === 'stable' ? '1' : ch.id === 'beta' ? '2' : '3'} {ch.label}
              </Text>
              <Text dimColor> - {ch.desc}</Text>
            </Box>
          ))}

          <Box marginTop={1}>
            <Text>Press [1/2/3] to select, [Enter] to install</Text>
          </Box>
        </>
      )}

      {step === 'installing' && (
        <Box flexDirection="column">
          <Text>{message}</Text>
          <Text dimColor>Please wait...</Text>
        </Box>
      )}

      {step === 'done' && (
        <Box flexDirection="column">
          <Text>{message}</Text>
          <Box marginTop={1}>
            <Text dimColor>Press [Enter] to continue</Text>
          </Box>
        </Box>
      )}
    </Box>
  );
}
