import React, { useState, useEffect } from 'react';
import { Box, Text } from 'ink';
import { Doctor, DiagnosticResult } from '../../core/doctor';

type DoctorStep = 'running' | 'results';

export function DoctorScreen() {
  const [step, setStep] = useState<DoctorStep>('running');
  const [results, setResults] = useState<DiagnosticResult | null>(null);

  useEffect(() => {
    const runDoctor = async () => {
      const doctor = new Doctor();
      const result = await doctor.run();
      setResults(result);
      setStep('results');
    };

    runDoctor();
  }, []);

  const getStatusColor = (status: string): string => {
    switch (status) {
      case 'pass': return 'green';
      case 'fail': return 'red';
      case 'warning': return 'yellow';
      default: return 'dim';
    }
  };

  const getStatusSymbol = (status: string): string => {
    switch (status) {
      case 'pass': return '✓';
      case 'fail': return '✗';
      case 'warning': return '!';
      default: return 'i';
    }
  };

  return (
    <Box flexDirection="column" padding={1}>
      <Text bold>OpenClaw 诊断</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>

      {step === 'running' && (
        <Text>正在运行诊断...</Text>
      )}

      {step === 'results' && results && (
        <>
          <Box flexDirection="column" marginBottom={1}>
            <Text>
              <Text dimColor>概要: </Text>
              <Text color="green">{results.summary.passed} 通过</Text>
              {results.summary.warnings > 0 && (
                <Text color="yellow"> • {results.summary.warnings} 警告</Text>
              )}
              {results.summary.errors > 0 && (
                <Text color="red"> • {results.summary.errors} 错误</Text>
              )}
            </Text>
          </Box>

          <Box flexDirection="column">
            {results.items.map((item) => (
              <Box key={item.id} marginBottom={1} flexDirection="column">
                <Box flexDirection="row">
                  <Box width={2}>
                    <Text color={getStatusColor(item.status)}>
                      {getStatusSymbol(item.status)}
                    </Text>
                  </Box>
                  <Text bold>{item.name}</Text>
                </Box>
                <Box paddingLeft={3} flexDirection="column">
                  <Text dimColor>{item.message}</Text>
                  {item.fix && (
                    <Text color="cyan">修复: {item.fix}</Text>
                  )}
                </Box>
              </Box>
            ))}
          </Box>

          <Box marginTop={1}>
            <Text dimColor>时间戳: {results.timestamp}</Text>
          </Box>
        </>
      )}

      <Box marginTop={1}>
        <Text dimColor>按 [回车] 重新诊断 | [Esc] 返回</Text>
      </Box>
    </Box>
  );
}
