import React, { useState, useEffect, useCallback } from 'react';
import { Box, Text } from 'ink';
import { SystemInfo, DockerInfo, WSLInfo } from '../../core/detector';
import { checkDockerStatus, checkWSLStatus } from '../../core/detector';
import { installOpenClaw, getVersionList, InstallChannel, InstallMethod, InstallPlatform, VersionInfo } from '../../core/installer';

type InstallStep = 'platform' | 'channel' | 'versions' | 'docker-check' | 'wsl-check' | 'installing' | 'done';
type SelectMode = 'channel' | 'version';

export function InstallScreen({ systemInfo }: { systemInfo: SystemInfo }) {
  const [step, setStep] = useState<InstallStep>('platform');
  const [selectMode, setSelectMode] = useState<SelectMode>('channel');
  const [selectedChannel, setSelectedChannel] = useState<InstallChannel>('stable');
  const [selectedVersion, setSelectedVersion] = useState<VersionInfo | null>(null);
  const [versionList, setVersionList] = useState<VersionInfo[]>([]);
  const [versionPage, setVersionPage] = useState(0);
  const [message, setMessage] = useState('');
  const [loadingVersions, setLoadingVersions] = useState(false);
  const [selectedPlatform, setSelectedPlatform] = useState<InstallPlatform>('native');
  const [dockerInfo, setDockerInfo] = useState<DockerInfo | null>(null);
  const [wslInfo, setWslInfo] = useState<WSLInfo | null>(null);
  const [cursorIndex, setCursorIndex] = useState(0);

  const VERSIONS_PER_PAGE = 10;

  const platforms: { id: InstallPlatform; label: string; desc: string }[] = [
    { id: 'native', label: 'Native Windows', desc: 'Install directly on Windows (recommended)' },
    { id: 'docker', label: 'Docker', desc: 'Run via Docker container (auto-detect Docker)' },
    { id: 'wsl', label: 'WSL', desc: 'Install inside Windows Subsystem for Linux' },
  ];

  const channels: { id: InstallChannel; label: string; desc: string }[] = [
    { id: 'stable', label: 'Stable', desc: 'Latest stable release (recommended)' },
    { id: 'beta', label: 'Beta', desc: 'Pre-release with new features' },
    { id: 'dev', label: 'Dev', desc: 'Development build (unstable)' },
  ];

  const installMethods: { id: InstallMethod; label: string; desc: string }[] = [
    { id: 'npm', label: 'NPM', desc: 'Install via npm (recommended)' },
    { id: 'script', label: 'Script', desc: 'Official install script' },
    { id: 'docker', label: 'Docker', desc: 'Run via Docker container' },
  ];

  const [selectedMethod, setSelectedMethod] = useState<InstallMethod>('npm');

  const loadVersions = useCallback(async () => {
    setLoadingVersions(true);
    const result = await getVersionList();
    if (result.success) {
      setVersionList(result.versions);
    }
    setLoadingVersions(false);
  }, []);

  const handleInstall = async () => {
    setStep('installing');
    const versionToInstall = selectedVersion?.version || selectedChannel;

    setMessage(`Installing OpenClaw (${versionToInstall})...`);

    const result = await installOpenClaw({
      method: selectedMethod,
      channel: selectedChannel,
      platform: selectedPlatform,
      version: selectedVersion?.version,
    });

    setMessage(result.message);
    setStep('done');
  };

  const handlePlatformSelect = useCallback((platform: InstallPlatform) => {
    setSelectedPlatform(platform);

    if (platform === 'docker') {
      setStep('docker-check');
      checkDockerStatus().then((info) => {
        setDockerInfo(info);
      });
    } else if (platform === 'wsl') {
      setStep('wsl-check');
      checkWSLStatus().then((info) => {
        setWslInfo(info);
      });
    } else {
      setStep('channel');
    }
  }, []);

  const handleKeypress = useCallback((data: Buffer) => {
    const key = data.toString();

    if (step === 'platform') {
      if (key === '\u001b[A') { // Arrow up
        setCursorIndex((i) => Math.max(0, i - 1));
      } else if (key === '\u001b[B') { // Arrow down
        setCursorIndex((i) => Math.min(platforms.length - 1, i + 1));
      } else if (key === ' ' || key === '\r' || key === '\n') {
        handlePlatformSelect(platforms[cursorIndex].id);
      }
    } else if (step === 'docker-check') {
      if (key === 'r') {
        checkDockerStatus().then((info) => {
          setDockerInfo(info);
        });
      } else if (key === 'b') {
        setStep('platform');
      } else if (dockerInfo?.running && (key === '\r' || key === '\n')) {
        setStep('channel');
      }
    } else if (step === 'wsl-check') {
      if (key === 'r') {
        checkWSLStatus().then((info) => {
          setWslInfo(info);
        });
      } else if (key === 'b') {
        setStep('platform');
      } else if (wslInfo?.installed && (key === '\r' || key === '\n')) {
        setStep('channel');
      }
    } else if (step === 'channel') {
      if (key === '\u001b[A') { // Arrow up
        setCursorIndex((i) => Math.max(0, i - 1));
      } else if (key === '\u001b[B') { // Arrow down
        setCursorIndex((i) => Math.min(channels.length - 1, i + 1));
      } else if (key === ' ') {
        setSelectedChannel(channels[cursorIndex].id);
      } else if (key === '\r' || key === '\n') {
        setSelectedChannel(channels[cursorIndex].id);
        setSelectedVersion(null);
        handleInstall();
      } else if (key === 'v') {
        loadVersions();
        setSelectMode('version');
        setStep('versions');
      } else if (key === 'b') {
        setStep('platform');
      }
    } else if (step === 'versions') {
      if (key === '\u001b[A') { // Arrow up
        setVersionPage((p) => Math.max(0, p - 1));
      } else if (key === '\u001b[B') { // Arrow down
        setVersionPage((p) => Math.min(Math.ceil(versionList.length / VERSIONS_PER_PAGE) - 1, p + 1));
      } else if (key === '\r' || key === '\n') {
        const idx = versionPage * VERSIONS_PER_PAGE;
        if (versionList[idx]) {
          setSelectedVersion(versionList[idx]);
          setSelectedChannel(versionList[idx].channel);
          handleInstall();
        }
      } else if (key === 'c') {
        setSelectMode('channel');
        setStep('channel');
      } else if (key === 'b') {
        setStep('platform');
      } else if (key >= '1' && key <= '9') {
        const idx = (versionPage * VERSIONS_PER_PAGE) + (parseInt(key) - 1);
        if (versionList[idx]) {
          setSelectedVersion(versionList[idx]);
          setSelectedChannel(versionList[idx].channel);
          handleInstall();
        }
      }
    } else if (step === 'done' && (key === '\r' || key === '\n')) {
      setStep('platform');
      setSelectMode('channel');
      setSelectedVersion(null);
    }
  }, [step, selectMode, selectedChannel, versionList, versionPage, loadVersions, handlePlatformSelect, dockerInfo, wslInfo, cursorIndex]);

  useEffect(() => {
    process.stdin.setRawMode(true);
    process.stdin.on('data', handleKeypress);
    return () => {
      process.stdin.setRawMode(false);
      process.stdin.removeAllListeners('data');
    };
  }, [handleKeypress]);

  const renderPlatformSelect = () => (
    <Box flexDirection="column" padding={1}>
      <Text bold>OpenClaw 安装</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>

      <Box marginBottom={1}>
        <Text>选择安装平台:</Text>
      </Box>
      {platforms.map((p, i) => {
        const isSelected = selectedPlatform === p.id;
        const isCursor = cursorIndex === i;
        return (
          <Box key={p.id} marginBottom={1}>
            <Box width={3}>
              <Text color={isCursor ? 'cyan' : undefined}>
                {isCursor ? '>' : ' '}
              </Text>
            </Box>
            <Text bold color={isCursor ? 'cyan' : undefined}>
              {p.label}
            </Text>
            <Text dimColor> - {p.desc}</Text>
          </Box>
        );
      })}

      <Box marginTop={1} marginBottom={1}>
        <Text dimColor> [↑/↓] 导航  [空格] 选中  [回车] 确认</Text>
      </Box>
    </Box>
  );

  const renderDockerCheck = () => {
    const isInstalled = dockerInfo?.installed;
    const isRunning = dockerInfo?.running;

    return (
      <Box flexDirection="column" padding={1}>
        <Text bold>Docker 状态检查</Text>
        <Box marginY={1}>
          <Text dimColor>─────────────────────────────────────</Text>
        </Box>

        {!dockerInfo ? (
          <Text>正在检查 Docker 状态...</Text>
        ) : isRunning ? (
          <>
            <Text color="green">Docker 已安装并正在运行</Text>
            {dockerInfo.version && <Text dimColor>版本: {dockerInfo.version}</Text>}
            <Box marginTop={1}>
              <Text>按 [回车] 继续 Docker 安装</Text>
            </Box>
          </>
        ) : isInstalled ? (
          <>
            <Text color="yellow">Docker 已安装但未运行</Text>
            <Text dimColor>请启动 Docker Desktop 后重试</Text>
            <Box marginTop={1}>
              <Text dimColor>按 [r] 刷新 | [b] 返回</Text>
            </Box>
          </>
        ) : (
          <>
            <Text color="yellow">Docker 未安装</Text>
            <Text dimColor>请先安装 Docker Desktop</Text>
            <Box marginTop={1}>
              <Text dimColor>按 [b] 返回</Text>
            </Box>
          </>
        )}
      </Box>
    );
  };

  const renderWSLCheck = () => {
    const isInstalled = wslInfo?.installed;

    return (
      <Box flexDirection="column" padding={1}>
        <Text bold>WSL 状态检查</Text>
        <Box marginY={1}>
          <Text dimColor>─────────────────────────────────────</Text>
        </Box>

        {!wslInfo ? (
          <Text>正在检查 WSL 状态...</Text>
        ) : isInstalled ? (
          <>
            <Text color="green">WSL 已安装</Text>
            {wslInfo.version && <Text dimColor>版本: WSL {wslInfo.version}</Text>}
            {wslInfo.distros.length > 0 && (
              <Text dimColor>发行版: {wslInfo.distros.join(', ')}</Text>
            )}
            <Box marginTop={1}>
              <Text>按 [回车] 继续 WSL 安装</Text>
            </Box>
          </>
        ) : (
          <>
            <Text color="yellow">WSL 未安装</Text>
            <Text dimColor>请先安装 WSL (运行: wsl --install)</Text>
            <Box marginTop={1}>
              <Text dimColor>按 [b] 返回</Text>
            </Box>
          </>
        )}
      </Box>
    );
  };

  const renderChannelSelect = () => (
    <Box flexDirection="column" padding={1}>
      <Text bold>OpenClaw 安装</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>

      <Box marginBottom={1}>
        <Text>平台: {selectedPlatform === 'native' ? '原生 Windows' : selectedPlatform === 'docker' ? 'Docker' : 'WSL'}</Text>
      </Box>

      <Box marginBottom={1}>
        <Text>选择版本通道:</Text>
      </Box>
      {channels.map((ch, i) => {
        const isSelected = selectedChannel === ch.id;
        const isCursor = cursorIndex === i;
        return (
          <Box key={ch.id} marginBottom={1}>
            <Box width={3}>
              <Text color={isCursor ? 'cyan' : undefined}>
                {isCursor ? '>' : ' '}
              </Text>
            </Box>
            <Text bold color={isCursor ? 'cyan' : undefined}>
              {ch.label}
            </Text>
            <Text dimColor> - {ch.desc}</Text>
          </Box>
        );
      })}

      <Box marginTop={1} marginBottom={1}>
        <Text dimColor>[v] 指定版本 | [b] 返回 | [回车] 安装</Text>
      </Box>
    </Box>
  );

  const renderVersionSelect = () => {
    const startIdx = versionPage * VERSIONS_PER_PAGE;
    const pageVersions = versionList.slice(startIdx, startIdx + VERSIONS_PER_PAGE);
    const totalPages = Math.ceil(versionList.length / VERSIONS_PER_PAGE);

    return (
      <Box flexDirection="column" padding={1}>
        <Text bold>选择 OpenClaw 版本</Text>
        <Box marginY={1}>
          <Text dimColor>─────────────────────────────────────</Text>
        </Box>

        {loadingVersions ? (
          <Text>正在加载版本...</Text>
        ) : (
          <>
            <Box marginBottom={1}>
              <Text dimColor>[↑/↓] 导航 | [空格] 选中 | [回车] 确认</Text>
            </Box>
            {pageVersions.map((v, i) => {
              const globalIdx = startIdx + i;
              const isSelected = selectedVersion?.version === v.version;
              const channelColor = v.channel === 'stable' ? 'green' : v.channel === 'beta' ? 'yellow' : 'red';
              return (
                <Box key={v.version} marginBottom={1}>
                  <Box width={3}>
                    <Text color={isSelected ? 'cyan' : undefined}>
                      {isSelected ? '>' : ' '}
                    </Text>
                  </Box>
                  <Box width={4}>
                    <Text color={isSelected ? 'cyan' : undefined}>{globalIdx + 1}</Text>
                  </Box>
                  <Box width={18}>
                    <Text bold color={isSelected ? 'cyan' : undefined}>
                      v{v.version}
                    </Text>
                  </Box>
                  <Text color={channelColor}>[{v.channel}]</Text>
                  {v.isLatest && <Text dimColor> (latest)</Text>}
                </Box>
              );
            })}

            <Box marginTop={1}>
              <Text dimColor>
                第 {versionPage + 1}/{totalPages} 页 | [c] 返回通道选择
              </Text>
            </Box>
          </>
        )}
      </Box>
    );
  };

  const renderInstalling = () => (
    <Box flexDirection="column" padding={1}>
      <Text bold>正在安装 OpenClaw...</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>
      <Text>{message}</Text>
      <Box marginTop={1}>
        <Text dimColor>请稍候...</Text>
      </Box>
    </Box>
  );

  const renderDone = () => (
    <Box flexDirection="column" padding={1}>
      <Text bold>安装完成</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>
      <Text>{message}</Text>
      <Box marginTop={1}>
        <Text dimColor>按 [回车] 继续</Text>
      </Box>
    </Box>
  );

  return (
    <Box flexDirection="column" padding={1}>
      {step === 'platform' && renderPlatformSelect()}
      {step === 'docker-check' && renderDockerCheck()}
      {step === 'wsl-check' && renderWSLCheck()}
      {step === 'channel' && renderChannelSelect()}
      {step === 'versions' && renderVersionSelect()}
      {step === 'installing' && renderInstalling()}
      {step === 'done' && renderDone()}
    </Box>
  );
}