import React, { useState, useEffect, useCallback } from 'react';
import { Box, Text } from 'ink';
import { SystemInfo, DockerInfo, WSLInfo } from '../../core/detector';
import { checkDockerStatus, checkWSLStatus } from '../../core/detector';
import { installOpenClaw, getVersionList, InstallPlatform, VersionInfo } from '../../core/installer';

type InstallStep = 'platform' | 'versions' | 'docker-check' | 'wsl-check' | 'installing' | 'done';

type InstallScreenProps = {
  systemInfo: SystemInfo;
  onExit: () => void;
};

export function InstallScreen({ systemInfo, onExit }: InstallScreenProps) {
  const [step, setStep] = useState<InstallStep>('platform');
  const [selectedVersion, setSelectedVersion] = useState<VersionInfo | null>(null);
  const [versionList, setVersionList] = useState<VersionInfo[]>([]);
  const [versionPage, setVersionPage] = useState(0);
  const [message, setMessage] = useState('');
  const [loadingVersions, setLoadingVersions] = useState(false);
  const [selectedPlatform, setSelectedPlatform] = useState<InstallPlatform>('native');
  const [dockerInfo, setDockerInfo] = useState<DockerInfo | null>(null);
  const [wslInfo, setWslInfo] = useState<WSLInfo | null>(null);
  const [cursorIndex, setCursorIndex] = useState(0);
  const [installError, setInstallError] = useState<string>('');

  const VERSIONS_PER_PAGE = 10;

  const platforms: { id: InstallPlatform; label: string; desc: string }[] = [
    { id: 'native', label: '原生 Windows', desc: '直接在 Windows 上安装（推荐）' },
    { id: 'docker', label: 'Docker', desc: '通过 Docker 容器运行（自动检测 Docker）' },
    { id: 'wsl', label: 'WSL', desc: '在 Windows 子系统 for Linux 中安装' },
  ];

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
    setInstallError('');
    const versionToInstall = selectedVersion?.version || 'stable';

    setMessage(`正在安装 OpenClaw (${versionToInstall})...`);

    const result = await installOpenClaw({
      method: 'npm',
      channel: 'stable',
      platform: selectedPlatform,
      version: selectedVersion?.version,
    });

    if (result.success) {
      setMessage(result.message);
      setStep('done');
    } else {
      // Capture detailed error
      setInstallError(result.message);
      setStep('done');
    }
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
      // native - directly install
      handleInstall();
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
      } else if (key === 'v') {
        loadVersions();
        setStep('versions');
      }
    } else if (step === 'docker-check') {
      if (key === 'r') {
        checkDockerStatus().then((info) => {
          setDockerInfo(info);
        });
      } else if (key === 'b') {
        setStep('platform');
      } else if (dockerInfo?.running && (key === '\r' || key === '\n')) {
        handleInstall();
      }
    } else if (step === 'wsl-check') {
      if (key === 'r') {
        checkWSLStatus().then((info) => {
          setWslInfo(info);
        });
      } else if (key === 'b') {
        setStep('platform');
      } else if (wslInfo?.installed && (key === '\r' || key === '\n')) {
        handleInstall();
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
          handleInstall();
        }
      } else if (key === 'b') {
        setStep('platform');
      } else if (key >= '1' && key <= '9') {
        const idx = (versionPage * VERSIONS_PER_PAGE) + (parseInt(key) - 1);
        if (versionList[idx]) {
          setSelectedVersion(versionList[idx]);
          handleInstall();
        }
      }
    } else if (step === 'done' && (key === '\r' || key === '\n' || key === '\x1b')) {
      // Return to main menu
      onExit();
    }
  }, [step, versionList, versionPage, loadVersions, handlePlatformSelect, dockerInfo, wslInfo, cursorIndex]);

  // Auto-proceed when Docker is detected as running
  useEffect(() => {
    if (step === 'docker-check' && dockerInfo?.running) {
      const timer = setTimeout(() => {
        handleInstall();
      }, 1000); // Auto proceed after 1 second
      return () => clearTimeout(timer);
    }
  }, [step, dockerInfo]);

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
        <Text dimColor>[↑/↓] 导航 | [空格/回车] 选择并安装 | [v] 指定版本</Text>
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
              <Text>正在自动继续安装...</Text>
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
              <Text dimColor>[↑/↓] 导航 | [回车] 选择版本 | [b] 返回</Text>
            </Box>
            {pageVersions.map((v, i) => {
              const globalIdx = startIdx + i;
              const isSelected = selectedVersion?.version === v.version;
              const channelColor = v.channel === 'stable' ? 'green' : v.channel === 'beta' ? 'yellow' : 'red';
              const channelLabel = v.channel === 'stable' ? '稳定版' : v.channel === 'beta' ? '测试版' : '开发版';
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
                  <Text color={channelColor}>[{channelLabel}]</Text>
                  {v.isLatest && <Text dimColor> (最新)</Text>}
                </Box>
              );
            })}

            <Box marginTop={1}>
              <Text dimColor>
                第 {versionPage + 1}/{totalPages} 页 | [b] 返回平台选择
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
      <Text bold>{installError ? '安装失败' : '安装完成'}</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>
      <Text color={installError ? 'red' : undefined}>{installError || message}</Text>
      {installError && selectedPlatform === 'docker' && (
        <Box flexDirection="column" marginTop={1}>
          <Text dimColor>常见问题：</Text>
          <Text dimColor>- Docker Desktop 未启动</Text>
          <Text dimColor>- 网络连接问题</Text>
          <Text dimColor>- 镜像不存在或需要登录</Text>
        </Box>
      )}
      <Box marginTop={1}>
        <Text dimColor>按 [回车] 返回主菜单</Text>
      </Box>
    </Box>
  );

  return (
    <Box flexDirection="column" padding={1}>
      {step === 'platform' && renderPlatformSelect()}
      {step === 'docker-check' && renderDockerCheck()}
      {step === 'wsl-check' && renderWSLCheck()}
      {step === 'versions' && renderVersionSelect()}
      {step === 'installing' && renderInstalling()}
      {step === 'done' && renderDone()}
    </Box>
  );
}