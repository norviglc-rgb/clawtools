import React, { useState, useEffect } from 'react';
import { Box, Text } from 'ink';
import { SecurityScanner, SecurityScanResult, PortScanResult, SecurityIssue } from '../../core/scanner';

type ScannerStep = 'authorize' | 'scanning' | 'results' | 'error';

export function ScannerScreen() {
  const [step, setStep] = useState<ScannerStep>('authorize');
  const [results, setResults] = useState<SecurityScanResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  const scanner = new SecurityScanner();

  useEffect(() => {
    const handleKeypress = (data: Buffer) => {
      const key = data.toString();

      if (step === 'authorize' && (key === 'y' || key === 'Y' || key === 'Enter')) {
        scanner.requestAuthorization('local');
        runScan();
      } else if (step === 'authorize' && (key === 'n' || key === 'N' || key === '\x1b')) {
        setStep('error');
        setError('Scan cancelled by user');
      }
    };

    process.stdin.on('data', handleKeypress);
    return () => {
      process.stdin.removeAllListeners('data');
    };
  }, [step]);

  const runScan = async () => {
    setStep('scanning');
    try {
      const result = await scanner.runLocalScan();
      setResults(result);
      setStep('results');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error occurred');
      setStep('error');
    }
  };

  const getSeverityColor = (severity: string): string => {
    switch (severity) {
      case 'critical': return 'red';
      case 'high': return 'red';
      case 'medium': return 'yellow';
      case 'low': return 'cyan';
      default: return 'dim';
    }
  };

  const getSeveritySymbol = (severity: string): string => {
    switch (severity) {
      case 'critical': return '!!';
      case 'high': return '!';
      case 'medium': return '~';
      case 'low': return '.';
      default: return '?';
    }
  };

  const renderAuthorizeStep = () => (
    <Box flexDirection="column" padding={1}>
      <Text bold>Security Scan Authorization</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>
      <Box flexDirection="column" marginBottom={1}>
        <Text>Before running the security scan, please note:</Text>
      </Box>
      <Box flexDirection="column" marginBottom={1}>
        <Text color="cyan">1. This scan will check firewall status</Text>
        <Text color="cyan">2. It will scan common ports on localhost</Text>
        <Text color="cyan">3. No data is sent to external servers</Text>
        <Text color="cyan">4. Only local network interfaces are scanned</Text>
      </Box>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>
      <Text bold>Do you want to proceed? [Y/n]</Text>
      <Box marginTop={1}>
        <Text dimColor>Press [Y] to start scan, [n] or [Esc] to cancel</Text>
      </Box>
    </Box>
  );

  const renderScanningStep = () => (
    <Box flexDirection="column" padding={1}>
      <Text bold>Security Scan in Progress</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>
      <Text>Scanning firewall status...</Text>
      <Text>Scanning common ports...</Text>
      <Text>Analyzing security issues...</Text>
      <Box marginTop={1}>
        <Text dimColor>Please wait...</Text>
      </Box>
    </Box>
  );

  const renderResultsStep = () => {
    if (!results) return null;

    return (
      <Box flexDirection="column" padding={1}>
        <Text bold>Security Scan Results</Text>
        <Box marginY={1}>
          <Text dimColor>─────────────────────────────────────</Text>
        </Box>

        <Box flexDirection="column" marginBottom={1}>
          <Text bold>Firewall Status</Text>
          <Text color={results.firewall.enabled ? 'green' : 'yellow'}>
            {results.firewall.enabled
              ? `Enabled (${results.firewall.platform})`
              : 'Disabled or Unknown'}
          </Text>
        </Box>

        <Box marginY={1}>
          <Text dimColor>─────────────────────────────────────</Text>
        </Box>

        <Box flexDirection="column" marginBottom={1}>
          <Text bold>Open Ports ({results.ports.length})</Text>
          {results.ports.length === 0 ? (
            <Text dimColor>No common ports are open</Text>
          ) : (
            results.ports.map((port: PortScanResult) => (
              <Text key={port.port} color="cyan">
                Port {port.port} ({port.service})
              </Text>
            ))
          )}
        </Box>

        <Box marginY={1}>
          <Text dimColor>─────────────────────────────────────</Text>
        </Box>

        <Box flexDirection="column" marginBottom={1}>
          <Text bold>Security Issues ({results.securityIssues.length})</Text>
          {results.securityIssues.length === 0 ? (
            <Text color="green">No security issues detected</Text>
          ) : (
            results.securityIssues.map((issue: SecurityIssue) => (
              <Box key={issue.id} marginBottom={1} flexDirection="column">
                <Box flexDirection="row">
                  <Text color={getSeverityColor(issue.severity)}>
                    {getSeveritySymbol(issue.severity)}
                  </Text>
                  <Text bold color={getSeverityColor(issue.severity)}>
                    {' '}{issue.title}
                  </Text>
                </Box>
                <Box paddingLeft={3} flexDirection="column">
                  <Text dimColor>{issue.description}</Text>
                  <Text color="green">Recommendation: {issue.recommendation}</Text>
                </Box>
              </Box>
            ))
          )}
        </Box>

        <Box marginY={1}>
          <Text dimColor>─────────────────────────────────────</Text>
        </Box>

        <Box flexDirection="column">
          <Text dimColor>Scan timestamp: {results.timestamp}</Text>
          <Text dimColor>Authorization: {results.authorized.scanType} scan</Text>
        </Box>
      </Box>
    );
  };

  const renderErrorStep = () => (
    <Box flexDirection="column" padding={1}>
      <Text bold color="red">Security Scan</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>
      <Text color="red">{error}</Text>
      <Box marginTop={1}>
        <Text dimColor>Press [Esc] to go back</Text>
      </Box>
    </Box>
  );

  return (
    <Box flexDirection="column" padding={1}>
      {step === 'authorize' && renderAuthorizeStep()}
      {step === 'scanning' && renderScanningStep()}
      {step === 'results' && renderResultsStep()}
      {step === 'error' && renderErrorStep()}
    </Box>
  );
}
