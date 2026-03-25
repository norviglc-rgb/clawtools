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
        setError('扫描被用户取消');
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
      <Text bold>安全扫描授权</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>
      <Box flexDirection="column" marginBottom={1}>
        <Text>运行安全扫描前，请注意:</Text>
      </Box>
      <Box flexDirection="column" marginBottom={1}>
        <Text color="cyan">1. 此扫描将检查防火墙状态</Text>
        <Text color="cyan">2. 它将扫描本地主机上的常见端口</Text>
        <Text color="cyan">3. 不会向外部服务器发送数据</Text>
        <Text color="cyan">4. 仅扫描本地网络接口</Text>
      </Box>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>
      <Text bold>是否继续? [Y/n]</Text>
      <Box marginTop={1}>
        <Text dimColor>按 [Y] 开始扫描 | [n] 或 [Esc] 取消</Text>
      </Box>
    </Box>
  );

  const renderScanningStep = () => (
    <Box flexDirection="column" padding={1}>
      <Text bold>正在执行安全扫描</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>
      <Text>正在扫描防火墙状态...</Text>
      <Text>正在扫描常见端口...</Text>
      <Text>正在分析安全问题...</Text>
      <Box marginTop={1}>
        <Text dimColor>请稍候...</Text>
      </Box>
    </Box>
  );

  const renderResultsStep = () => {
    if (!results) return null;

    return (
      <Box flexDirection="column" padding={1}>
        <Text bold>安全扫描结果</Text>
        <Box marginY={1}>
          <Text dimColor>─────────────────────────────────────</Text>
        </Box>

        <Box flexDirection="column" marginBottom={1}>
          <Text bold>防火墙状态</Text>
          <Text color={results.firewall.enabled ? 'green' : 'yellow'}>
            {results.firewall.enabled
              ? `已启用 (${results.firewall.platform})`
              : '已禁用或未知'}
          </Text>
        </Box>

        <Box marginY={1}>
          <Text dimColor>─────────────────────────────────────</Text>
        </Box>

        <Box flexDirection="column" marginBottom={1}>
          <Text bold>开放端口 ({results.ports.length})</Text>
          {results.ports.length === 0 ? (
            <Text dimColor>没有开放的常见端口</Text>
          ) : (
            results.ports.map((port: PortScanResult) => (
              <Text key={port.port} color="cyan">
                端口 {port.port} ({port.service})
              </Text>
            ))
          )}
        </Box>

        <Box marginY={1}>
          <Text dimColor>─────────────────────────────────────</Text>
        </Box>

        <Box flexDirection="column" marginBottom={1}>
          <Text bold>安全问题 ({results.securityIssues.length})</Text>
          {results.securityIssues.length === 0 ? (
            <Text color="green">未检测到安全问题</Text>
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
                  <Text color="green">建议: {issue.recommendation}</Text>
                </Box>
              </Box>
            ))
          )}
        </Box>

        <Box marginY={1}>
          <Text dimColor>─────────────────────────────────────</Text>
        </Box>

        <Box flexDirection="column">
          <Text dimColor>扫描时间: {results.timestamp}</Text>
          <Text dimColor>授权: {results.authorized.scanType} 扫描</Text>
        </Box>
      </Box>
    );
  };

  const renderErrorStep = () => (
    <Box flexDirection="column" padding={1}>
      <Text bold color="red">安全扫描</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>
      <Text color="red">{error}</Text>
      <Box marginTop={1}>
        <Text dimColor>按 [Esc] 返回</Text>
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
