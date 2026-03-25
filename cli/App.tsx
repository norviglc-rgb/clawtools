import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import { Box, Text } from 'ink';
import { SystemInfo } from '../core/detector';
import { InstallScreen } from './screens/install';
import { ConfigScreen } from './screens/config';
import { DoctorScreen } from './screens/doctor';
import { BackupScreen } from './screens/backup';
import { SearchScreen } from './screens/search';
import { ScannerScreen } from './screens/scanner';
import { MigrationScreen } from './screens/migration';

type MenuItem = 'install' | 'config' | 'doctor' | 'backup' | 'search' | 'scanner' | 'migrate' | 'exit';

interface MenuItemConfig {
  label: string;
  description: string;
  shortcut: string;
}

const THEME = {
  primary: 'cyan',
  secondary: 'blue',
  success: 'green',
  warning: 'yellow',
  error: 'red',
  dim: 'gray',
};

const menuItems: Record<MenuItem, MenuItemConfig> = {
  install: { label: '安装', description: '安装或更新 OpenClaw', shortcut: '1' },
  config: { label: '配置', description: '配置提供商和设置', shortcut: '2' },
  doctor: { label: '诊断', description: '运行诊断检查', shortcut: '3' },
  backup: { label: '备份', description: '备份和恢复数据', shortcut: '4' },
  search: { label: '搜索', description: '搜索文档', shortcut: '5' },
  scanner: { label: '扫描', description: '安全扫描 (防火墙/端口)', shortcut: '6' },
  migrate: { label: '迁移', description: '跨平台迁移导出', shortcut: '7' },
  exit: { label: '退出', description: '退出 ClawTools', shortcut: 'q' },
};

export function App({ systemInfo }: { systemInfo: SystemInfo }) {
  const [selectedMenu, setSelectedMenu] = useState<MenuItem>('install');
  const [showScreen, setShowScreen] = useState(false);
  const [cursorIndex, setCursorIndex] = useState(0);

  const menuKeys = useMemo(() => Object.keys(menuItems) as MenuItem[], []);

  // Global keypress handler for quit
  useEffect(() => {
    const handleGlobalKeypress = (data: Buffer) => {
      const key = data.toString();
      // q or Q always exits
      if (key === 'q' || key === 'Q' || key === 'q\r' || key === 'Q\r') {
        process.exit(0);
      }
    };

    process.stdin.setRawMode(true);
    process.stdin.on('data', handleGlobalKeypress);

    return () => {
      process.stdin.setRawMode(false);
      process.stdin.removeAllListeners('data');
    };
  }, []);

  // Menu navigation handler
  useEffect(() => {
    if (showScreen) return;

    const handleKeypress = (data: Buffer) => {
      const key = data.toString();

      if (key === '\u001b[A') { // Arrow up
        const newIndex = Math.max(0, cursorIndex - 1);
        setCursorIndex(newIndex);
        setSelectedMenu(menuKeys[newIndex]);
      } else if (key === '\u001b[B') { // Arrow down
        const newIndex = Math.min(menuKeys.length - 1, cursorIndex + 1);
        setCursorIndex(newIndex);
        setSelectedMenu(menuKeys[newIndex]);
      } else if (key === '\r' || key === '\n') { // Enter
        const selected = menuKeys[cursorIndex];
        if (selected === 'exit') {
          process.exit(0);
        }
        setShowScreen(true);
      } else {
        // Number keys 1-7
        const num = parseInt(key);
        if (num >= 1 && num <= 7) {
          const menuKey = menuKeys[num - 1];
          if (menuKey === 'exit') {
            process.exit(0);
          }
          setSelectedMenu(menuKey);
          setCursorIndex(num - 1);
          setShowScreen(true);
        }
      }
    };

    process.stdin.setRawMode(true);
    process.stdin.on('data', handleKeypress);

    return () => {
      process.stdin.removeAllListeners('data');
    };
  }, [showScreen, cursorIndex, menuKeys]);

  const renderMenu = () => (
    <Box flexDirection="column">
      <Box marginBottom={1}>
        <Text bold color={THEME.primary}>ClawTools v0.1.0</Text>
      </Box>

      <Box flexDirection="row" marginBottom={1}>
        <Text dimColor>Platform: </Text>
        <Text>{systemInfo.platform} ({systemInfo.arch})</Text>
        <Text dimColor>  |  Node.js: </Text>
        <Text color={systemInfo.node.meetsRequirement ? THEME.success : THEME.error}>
          {systemInfo.node.installed ? systemInfo.node.version : 'Not installed'}
        </Text>
      </Box>

      <Box borderStyle="single" borderColor={THEME.dim} marginBottom={1}></Box>

      <Box marginBottom={1}>
        <Text bold>选择操作:</Text>
      </Box>

      {menuKeys.map((key, index) => {
        const item = menuItems[key];
        const isCursor = cursorIndex === index;

        return (
          <Box key={key} flexDirection="row">
            <Text color={isCursor ? THEME.primary : THEME.dim}>
              {isCursor ? '▶ ' : '  '}
            </Text>
            <Text bold={isCursor} color={isCursor ? THEME.primary : undefined}>
              [{item.shortcut}]
            </Text>
            <Text color={isCursor ? THEME.primary : undefined}> {item.label}</Text>
            <Text dimColor> - {item.description}</Text>
          </Box>
        );
      })}

      <Box marginTop={1} borderStyle="single" borderColor={THEME.dim}></Box>

      <Box marginTop={1}>
        <Text dimColor>[↑↓] 导航  [回车] 选择  [1-7] 快捷  [Q] 退出</Text>
      </Box>
    </Box>
  );

  const renderScreen = () => {
    switch (selectedMenu) {
      case 'install':
        return <InstallScreen systemInfo={systemInfo} onExit={() => setShowScreen(false)} />;
      case 'config':
        return <ConfigScreen />;
      case 'doctor':
        return <DoctorScreen />;
      case 'backup':
        return <BackupScreen />;
      case 'search':
        return <SearchScreen />;
      case 'scanner':
        return <ScannerScreen />;
      case 'migrate':
        return <MigrationScreen />;
      default:
        return null;
    }
  };

  if (showScreen) {
    return (
      <Box flexDirection="column">
        <Box marginBottom={1}>
          <Text dimColor>[Esc] 返回</Text>
        </Box>
        {renderScreen()}
      </Box>
    );
  }

  return (
    <Box flexDirection="column" padding={1}>
      <Box borderStyle="round" borderColor={THEME.primary} padding={1}>
        {renderMenu()}
      </Box>
    </Box>
  );
}
