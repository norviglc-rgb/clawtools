import React, { useState, useEffect, useCallback } from 'react';
import { Box, Text } from 'ink';
import {
  exportForMigration,
  listMigrationPlatforms,
  MigrationPlatform,
  MigrationExportResult,
} from '../../core/migration';
import * as path from 'path';
import * as os from 'os';

type MigrationStep = 'select' | 'exporting' | 'done';

export function MigrationScreen() {
  const [step, setStep] = useState<MigrationStep>('select');
  const [selectedPlatform, setSelectedPlatform] = useState<MigrationPlatform>('docker');
  const [message, setMessage] = useState('');
  const [exportResult, setExportResult] = useState<MigrationExportResult | null>(null);

  const platforms: { id: MigrationPlatform; label: string; desc: string }[] = [
    { id: 'docker', label: 'Docker', desc: 'Containerized deployment' },
    { id: 'hyperv', label: 'Hyper-V', desc: 'Windows virtualization' },
    { id: 'native', label: 'Native', desc: 'Direct installation' },
  ];

  const handleExport = async () => {
    setStep('exporting');
    setMessage(`Creating migration package for ${selectedPlatform}...`);

    const result = await exportForMigration(selectedPlatform);

    setExportResult(result);
    setMessage(result.message);
    setStep('done');
  };

  const handleKeypress = useCallback((data: Buffer) => {
    const key = data.toString();

    if (step === 'select') {
      if (key === '1') setSelectedPlatform('docker');
      else if (key === '2') setSelectedPlatform('hyperv');
      else if (key === '3') setSelectedPlatform('native');
      else if (key === '\r' || key === '\n') handleExport();
    } else if (step === 'done' && (key === '\r' || key === '\n' || key === '\x1b')) {
      setStep('select');
      setMessage('');
      setExportResult(null);
    }
  }, [step, selectedPlatform]);

  useEffect(() => {
    process.stdin.setRawMode(true);
    process.stdin.on('data', handleKeypress);
    return () => {
      process.stdin.setRawMode(false);
      process.stdin.removeAllListeners('data');
    };
  }, [handleKeypress]);

  return (
    <Box flexDirection="column" padding={1}>
      <Text bold>Migration Export</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>

      {step === 'select' && (
        <>
          <Box marginBottom={1}>
            <Text>Select target platform:</Text>
          </Box>
          {platforms.map((p) => (
            <Box key={p.id} marginBottom={1}>
              <Box width={3}>
                <Text color={selectedPlatform === p.id ? 'cyan' : undefined}>
                  [{selectedPlatform === p.id ? 'x' : ' '}]
                </Text>
              </Box>
              <Text bold color={selectedPlatform === p.id ? 'cyan' : undefined}>
                {p.id === 'docker' ? '1' : p.id === 'hyperv' ? '2' : '3'} {p.label}
              </Text>
              <Text dimColor> - {p.desc}</Text>
            </Box>
          ))}

          <Box marginTop={1}>
            <Text dimColor>Press [1/2/3] to select, [Enter] to export</Text>
          </Box>
        </>
      )}

      {step === 'exporting' && (
        <Box flexDirection="column">
          <Text>{message}</Text>
          <Box marginTop={1}>
            <Text dimColor>Please wait...</Text>
          </Box>
        </Box>
      )}

      {step === 'done' && (
        <>
          <Box flexDirection="column">
            <Text bold color={exportResult?.success ? 'green' : 'red'}>
              {exportResult?.success ? 'Export Successful' : 'Export Failed'}
            </Text>
            <Box marginY={1}>
              <Text>{message}</Text>
            </Box>
            {exportResult?.success && exportResult.exportPath && (
              <Box flexDirection="column" marginY={1}>
                <Text dimColor>Export location:</Text>
                <Text>{exportResult.exportPath}</Text>
              </Box>
            )}
            {exportResult?.success && exportResult.manifest && (
              <Box flexDirection="column" marginTop={1}>
                <Text dimColor>Instructions:</Text>
                <Box marginTop={1} paddingLeft={1} borderStyle="round" borderColor="dimColor">
                  <Text>
                    {exportResult.manifest.instructions.split('\n').map((line, i) => (
                      <Text key={i}>{line}{i < exportResult.manifest!.instructions.split('\n').length - 1 ? '\n' : ''}</Text>
                    ))}
                  </Text>
                </Box>
              </Box>
            )}
          </Box>
          <Box marginTop={1}>
            <Text dimColor>Press [Enter] to continue</Text>
          </Box>
        </>
      )}
    </Box>
  );
}