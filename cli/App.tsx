import React, { useState, useEffect } from 'react';
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

  const menuKeys = Object.keys(menuItems) as MenuItem[];

  useEffect(() => {
    const handleKeypress = (data: Buffer) => {
      const key = data.toString();

      if (showScreen && key === '\x1b') {
        setShowScreen(false);
        return;
      }

      if (!showScreen) {
        // Arrow key navigation
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
          setSelectedMenu(selected);
          setShowScreen(true);
        } else {
          // Number key shortcuts
          const item = Object.entries(menuItems).find(([, config]) => config.shortcut === key);
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
  }, [showScreen, cursorIndex, menuKeys]);

  const renderMenu = () => (
    <Box flexDirection="column" padding={1}>
      <Box flexDirection="column" marginBottom={1}>
        <Text bold>平台: </Text>
        <Text>{systemInfo.platform} ({systemInfo.arch})</Text>
      </Box>

      <Box flexDirection="column" marginBottom={1}>
        <Text bold>Node.js: </Text>
        <Text color={systemInfo.node.meetsRequirement ? 'green' : 'red'}>
          {systemInfo.node.installed ? systemInfo.node.version : '未安装'}
        </Text>
      </Box>

      <Box flexDirection="column" marginBottom={1}>
        <Text bold>OpenClaw: </Text>
        <Text color={systemInfo.openclaw.installed ? 'green' : 'yellow'}>
          {systemInfo.openclaw.installed
            ? `v${systemInfo.openclaw.version || 'unknown'}`
            : '未安装'}
        </Text>
      </Box>

      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>

      <Box marginBottom={1}>
        <Text bold>请选择操作:</Text>
      </Box>

      {menuKeys.map((key, index) => {
        const item = menuItems[key];
        const isSelected = selectedMenu === key;
        const isCursor = cursorIndex === index;

        return (
          <Box key={key} flexDirection="row" marginBottom={1}>
            <Box width={3}>
              <Text color={isCursor ? 'cyan' : undefined}>
                {isCursor ? '>' : ' '}
              </Text>
            </Box>
            <Box width={3}>
              <Text bold={isSelected} color={isCursor ? 'cyan' : undefined}>
                {item.shortcut}
              </Text>
            </Box>
            <Box flexDirection="column" width={40}>
              <Text bold={isSelected} color={isCursor ? 'cyan' : undefined}>{item.label}</Text>
              <Text dimColor>{item.description}</Text>
            </Box>
          </Box>
        );
      })}

      <Box marginTop={1}>
        <Text dimColor>[↑/↓] 导航 • [回车] 选择 • [q] 退出</Text>
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
        <Box padding={1} borderStyle="round" borderColor="blue">
          <Text dimColor>按 [Esc] 返回</Text>
        </Box>
        {renderScreen()}
      </Box>
    );
  }

  return (
    <Box flexDirection="column">
      <Box padding={1} borderStyle="round" borderColor="cyan">
        {renderMenu()}
      </Box>
    </Box>
  );
}
