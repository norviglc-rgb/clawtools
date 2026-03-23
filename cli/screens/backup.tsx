import React, { useState, useEffect } from 'react';
import { Box, Text } from 'ink';
import { BackupManager, BackupOptions, BackupInfo } from '../../core/backup';

type BackupStep = 'menu' | 'creating' | 'restoring' | 'done';

export function BackupScreen() {
  const [step, setStep] = useState<BackupStep>('menu');
  const [backups, setBackups] = useState<BackupInfo[]>([]);
  const [message, setMessage] = useState('');
  const [selectedBackup, setSelectedBackup] = useState<string | null>(null);

  const backupManager = new BackupManager();

  useEffect(() => {
    setBackups(backupManager.listBackups());
  }, []);

  const handleCreateBackup = async () => {
    setStep('creating');
    setMessage('Creating backup...');

    const options: BackupOptions = {
      includeConfig: true,
      includeWorkspace: true,
      includeSkills: true,
      includePlugins: true,
    };

    const result = await backupManager.createBackup(options);

    if (result.success) {
      setMessage(`Backup created: ${result.backupPath} (${formatSize(result.size || 0)})`);
      setBackups(backupManager.listBackups());
    } else {
      setMessage(`Backup failed: ${result.message}`);
    }

    setStep('done');
  };

  const handleRestoreBackup = async (backupPath: string) => {
    setStep('restoring');
    setMessage('Restoring backup...');

    const result = await backupManager.restoreBackup(backupPath);

    setMessage(result.message);
    setStep('done');
  };

  const formatSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const formatDate = (dateStr: string): string => {
    const date = new Date(dateStr);
    return date.toLocaleString();
  };

  useEffect(() => {
    const handler = (data: Buffer) => {
      const key = data.toString();

      if (step === 'menu') {
        if (key === '1') handleCreateBackup();
        else if (key === '2' && backups.length > 0) {
          setSelectedBackup(backups[0].path);
          handleRestoreBackup(backups[0].path);
        }
        else if (key === '\x1b') {
          return;
        }
      } else if (step === 'done') {
        if (key === '\r' || key === '\n' || key === '\x1b') {
          setStep('menu');
          setMessage('');
        }
      }
    };

    process.stdin.setRawMode(true);
    process.stdin.on('data', handler);

    return () => {
      process.stdin.setRawMode(false);
      process.stdin.removeAllListeners('data');
    };
  }, [step, backups, selectedBackup]);

  return (
    <Box flexDirection="column" padding={1}>
      <Text bold>Backup & Restore</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>

      {step === 'menu' && (
        <>
          <Box marginBottom={1}>
            <Box width={3}>
              <Text color="cyan">[1]</Text>
            </Box>
            <Text bold> Create Backup</Text>
            <Text dimColor> - Backup all OpenClaw data</Text>
          </Box>

          <Box marginBottom={2}>
            <Box width={3}>
              <Text color="cyan">[2]</Text>
            </Box>
            <Text bold> Restore</Text>
            <Text dimColor> - Restore from backup</Text>
          </Box>

          {backups.length > 0 && (
            <>
              <Box marginBottom={1}>
                <Text dimColor>Recent backups:</Text>
              </Box>
              {backups.slice(0, 5).map((backup, index) => {
                const filename = backup.path.split(/[/\\]/).pop() || backup.path;
                return (
                  <Box key={backup.id} marginBottom={1}>
                    <Text dimColor>{index + 1}.</Text>
                    <Text> {filename}</Text>
                    <Text dimColor> ({formatSize(backup.size)})</Text>
                  </Box>
                );
              })}
            </>
          )}

          {backups.length === 0 && (
            <Text dimColor>No backups found</Text>
          )}
        </>
      )}

      {step === 'creating' && (
        <Text>{message}</Text>
      )}

      {step === 'restoring' && (
        <Text>{message}</Text>
      )}

      {step === 'done' && (
        <>
          <Text>{message}</Text>
          <Box marginTop={1}>
            <Text dimColor>Press any key to continue</Text>
          </Box>
        </>
      )}

      <Box marginTop={1}>
        <Text dimColor>Press [1] create, [2] restore, [Esc] go back</Text>
      </Box>
    </Box>
  );
}
