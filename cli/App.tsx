import React, { useState, useEffect, useRef, useMemo } from 'react';
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
  emoji: string;
}

const THEME = {
  primary: 'cyan',
  secondary: 'blue',
  success: 'green',
  warning: 'yellow',
  error: 'red',
  dim: 'gray',
  accent: 'magenta',
};

const ASCII_LOGO = `
   ___ _        _     ____
  / __| |_ __ _| |_  |_  _|__  ___
  \__ \  _/ _' |  _|   | |/ _ \/ -_)
  |___/\__\__,_|\__|  |_|\___/\___|
        Tools for OpenClaw
`;

const menuItems: Record<MenuItem, MenuItemConfig> = {
  install: { label: '安装', description: '安装或更新 OpenClaw', shortcut: '1', emoji: ' ' },
  config: { label: '配置', description: '配置提供商和设置', shortcut: '2', emoji: ' ' },
  doctor: { label: '诊断', description: '运行诊断检查', shortcut: '3', emoji: ' ' },
  backup: { label: '备份', description: '备份和恢复数据', shortcut: '4', emoji: ' ' },
  search: { label: '搜索', description: '搜索文档', shortcut: '5', emoji: ' ' },
  scanner: { label: '扫描', description: '安全扫描 (防火墙/端口)', shortcut: '6', emoji: ' ' },
  migrate: { label: '迁移', description: '跨平台迁移导出', shortcut: '7', emoji: ' ' },
  exit: { label: '退出', description: '退出 ClawTools', shortcut: 'q', emoji: ' ' },
};

export function App({ systemInfo }: { systemInfo: SystemInfo }) {
  const [selectedMenu, setSelectedMenu] = useState<MenuItem>('install');
  const [showScreen, setShowScreen] = useState(false);
  const [cursorIndex, setCursorIndex] = useState(0);

  const cursorIndexRef = useRef(cursorIndex);
  const showScreenRef = useRef(showScreen);
  const menuKeys = useMemo(() => Object.keys(menuItems) as MenuItem[], []);

  useEffect(() => {
    cursorIndexRef.current = cursorIndex;
  }, [cursorIndex]);

  useEffect(() => {
    showScreenRef.current = showScreen;
  }, [showScreen]);

  useEffect(() => {
    const handleKeypress = (data: Buffer) => {
      const key = data.toString();

      if (showScreenRef.current && key === '\x1b') {
        setShowScreen(false);
        return;
      }

      if (!showScreenRef.current) {
        // Normalize key - remove trailing carriage return/newline
        const normalizedKey = key.replace(/[\r\n]$/, '');

        if (key === '\u001b[A') {
          const newIndex = Math.max(0, cursorIndexRef.current - 1);
          setCursorIndex(newIndex);
          setSelectedMenu(menuKeys[newIndex]);
        } else if (key === '\u001b[B') {
          const newIndex = Math.min(menuKeys.length - 1, cursorIndexRef.current + 1);
          setCursorIndex(newIndex);
          setSelectedMenu(menuKeys[newIndex]);
        } else if (normalizedKey === 'q' || normalizedKey === 'Q') {
          // Quit on 'q' or 'Q'
          process.exit(0);
        } else if (key === '\r' || key === '\n') {
          const selected = menuKeys[cursorIndexRef.current];
          if (selected === 'exit') {
            process.exit(0);
          }
          setSelectedMenu(selected);
          setShowScreen(true);
        } else {
          const item = Object.entries(menuItems).find(([, config]) => config.shortcut === normalizedKey);
          if (item) {
            if (item[0] === 'exit') {
              process.exit(0);
            }
            setSelectedMenu(item[0] as MenuItem);
            setCursorIndex(menuKeys.indexOf(item[0] as MenuItem));
            setShowScreen(true);
          }
        }
      }
    };

    process.stdin.setRawMode(true);
    process.stdin.on('data', handleKeypress);

    return () => {
      process.stdin.setRawMode(false);
      process.stdin.removeAllListeners('data');
    };
  }, [menuKeys]);

  const renderMenu = () => (
    <Box flexDirection="column" padding={1}>
      <Box marginBottom={1}>
        <Text color={THEME.primary} bold>
          {ASCII_LOGO}
        </Text>
      </Box>

      <Box flexDirection="row" marginBottom={1} gap={2}>
        <Box flexDirection="column" flexGrow={1}>
          <Text bold color={THEME.dim}>Platform:</Text>
          <Text>{systemInfo.platform} ({systemInfo.arch})</Text>
        </Box>
        <Box flexDirection="column" flexGrow={1}>
          <Text bold color={THEME.dim}>Node.js:</Text>
          <Text color={systemInfo.node.meetsRequirement ? THEME.success : THEME.error}>
            {systemInfo.node.installed ? systemInfo.node.version : 'Not installed'}
          </Text>
        </Box>
        <Box flexDirection="column" flexGrow={1}>
          <Text bold color={THEME.dim}>OpenClaw:</Text>
          <Text color={systemInfo.openclaw.installed ? THEME.success : THEME.warning}>
            {systemInfo.openclaw.installed
              ? `v${systemInfo.openclaw.version || 'unknown'}`
              : 'Not installed'}
          </Text>
        </Box>
      </Box>

      <Box marginY={1}>
        <Text dimColor>{'─'.repeat(50)}</Text>
      </Box>

      <Box marginBottom={1}>
        <Text bold color={THEME.primary}>Select an action:</Text>
      </Box>

      {menuKeys.map((key, index) => {
        const item = menuItems[key];
        const isSelected = selectedMenu === key;
        const isCursor = cursorIndex === index;

        return (
          <Box key={key} flexDirection="row" marginBottom={1}>
            <Box width={3}>
              <Text color={isCursor ? THEME.primary : THEME.dim}>
                {isCursor ? '▶' : ' '}
              </Text>
            </Box>
            <Box width={4}>
              <Text bold color={isCursor ? THEME.accent : THEME.secondary}>
                [{item.shortcut}]
              </Text>
            </Box>
            <Text
              bold={isSelected}
              color={isCursor ? THEME.primary : isSelected ? THEME.secondary : undefined}
            >
              {item.emoji} {item.label}
            </Text>
            <Text dimColor>  {item.description}</Text>
          </Box>
        );
      })}

      <Box marginTop={1}>
        <Text dimColor>{'─'.repeat(50)}</Text>
      </Box>

      <Box marginTop={1}>
        <Text dimColor>[↑/↓] Navigate  [Enter] Select  [1-7] Quick select  [Q] Quit</Text>
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
        <Box padding={1} borderStyle="bold" borderColor={THEME.primary}>
          <Text dimColor>Press [Esc] to go back</Text>
        </Box>
        {renderScreen()}
      </Box>
    );
  }

  return (
    <Box flexDirection="column">
      <Box padding={1} borderStyle="bold" borderColor={THEME.primary}>
        <Text color={THEME.primary} bold>
          {'┌' + '─'.repeat(48) + '┐'}
        </Text>
      </Box>
      <Box padding={1} borderStyle="bold" borderColor={THEME.primary}>
        {renderMenu()}
      </Box>
      <Box padding={1} borderStyle="bold" borderColor={THEME.primary}>
        <Text color={THEME.primary} bold>
          {'└' + '─'.repeat(48) + '┘'}
        </Text>
      </Box>
    </Box>
  );
}
