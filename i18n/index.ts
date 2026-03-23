export type Locale = 'zh-CN' | 'en';

export interface LocaleConfig {
  code: Locale;
  name: string;
  nativeName: string;
}

export const supportedLocales: LocaleConfig[] = [
  { code: 'zh-CN', name: 'Chinese (Simplified)', nativeName: '简体中文' },
  { code: 'en', name: 'English', nativeName: 'English' },
];

export const defaultLocale: Locale = 'zh-CN';

export interface TranslationKeys {
  // App
  'app.title': string;
  'app.subtitle': string;
  'app.platform': string;
  'app.nodejs': string;
  'app.openclaw': string;
  'app.notInstalled': string;
  'app.version': string;

  // Menu
  'menu.select': string;
  'menu.exit': string;
  'menu.exitHint': string;

  // Install
  'install.title': string;
  'install.selectChannel': string;
  'install.channel.stable': string;
  'install.channel.stableDesc': string;
  'install.channel.beta': string;
  'install.channel.betaDesc': string;
  'install.channel.dev': string;
  'install.channel.devDesc': string;
  'install.pressNumber': string;
  'install.pressEnter': string;
  'install.installing': string;
  'install.success': string;
  'install.failed': string;
  'install.pressKey': string;

  // Config
  'config.title': string;
  'config.selectProvider': string;
  'config.enterApiKey': string;
  'config.saved': string;
  'config.configured': string;
  'config.pressNumber': string;

  // Doctor
  'doctor.title': string;
  'doctor.running': string;
  'doctor.summary': string;
  'doctor.passed': string;
  'doctor.warnings': string;
  'doctor.errors': string;
  'doctor.fix': string;
  'doctor.timestamp': string;
  'doctor.pressEnter': string;

  // Backup
  'backup.title': string;
  'backup.create': string;
  'backup.restore': string;
  'backup.noBackups': string;
  'backup.creating': string;
  'backup.restoring': string;
  'backup.success': string;
  'backup.failed': string;
  'backup.pressKey': string;
  'backup.recent': string;

  // Search
  'search.title': string;
  'search.clone': string;
  'search.cloneHint': string;
  'search.cloneProgress': string;
  'search.success': string;
  'search.failed': string;
  'search.query': string;
  'search.results': string;
  'search.noResults': string;
  'search.pressEnter': string;

  // Common
  'common.loading': string;
  'common.error': string;
  'common.success': string;
  'common.warning': string;
  'common.info': string;
  'common.yes': string;
  'common.no': string;
  'common.cancel': string;
  'common.confirm': string;
  'common.back': string;
  'common.quit': string;
}

const translations: Record<Locale, Partial<TranslationKeys>> = {
  'zh-CN': {
    // App
    'app.title': 'ClawTools',
    'app.subtitle': 'OpenClaw 管理套件',
    'app.platform': '平台',
    'app.nodejs': 'Node.js',
    'app.openclaw': 'OpenClaw',
    'app.notInstalled': '未安装',
    'app.version': '版本',

    // Menu
    'menu.select': '选择一个选项',
    'menu.exit': '退出',
    'menu.exitHint': '按 [q] 退出 • 按数字选择',

    // Install
    'install.title': '安装 OpenClaw',
    'install.selectChannel': '选择版本通道',
    'install.channel.stable': '稳定版',
    'install.channel.stableDesc': '最新稳定版本（推荐）',
    'install.channel.beta': '测试版',
    'install.channel.betaDesc': '预发布版本，包含新功能',
    'install.channel.dev': '开发版',
    'install.channel.devDesc': '开发构建（不稳定）',
    'install.pressNumber': '按 [1/2/3] 选择，按 [Enter] 安装',
    'install.installing': '正在安装...',
    'install.success': '安装成功！',
    'install.failed': '安装失败',
    'install.pressKey': '按任意键继续',

    // Config
    'config.title': 'Provider 配置',
    'config.selectProvider': '选择要配置的 Provider',
    'config.enterApiKey': '输入 API Key（按 Enter 保存）',
    'config.saved': 'API Key 已保存',
    'config.configured': '已配置',
    'config.pressNumber': '按 [1-{n}] 选择，按 [q] 退出',

    // Doctor
    'doctor.title': 'OpenClaw 诊断',
    'doctor.running': '正在运行诊断...',
    'doctor.summary': '摘要',
    'doctor.passed': '通过',
    'doctor.warnings': '警告',
    'doctor.errors': '错误',
    'doctor.fix': '修复建议',
    'doctor.timestamp': '时间戳',
    'doctor.pressEnter': '按 [Enter] 运行 openclaw doctor，按 [Esc] 返回',

    // Backup
    'backup.title': '备份与恢复',
    'backup.create': '创建备份',
    'backup.restore': '恢复备份',
    'backup.noBackups': '暂无备份',
    'backup.creating': '正在创建备份...',
    'backup.restoring': '正在恢复备份...',
    'backup.success': '操作成功',
    'backup.failed': '操作失败',
    'backup.pressKey': '按 [1] 创建，按 [2] 恢复，按 [Esc] 返回',
    'backup.recent': '最近的备份',

    // Search
    'search.title': '文档搜索',
    'search.clone': '克隆文档',
    'search.cloneHint': '这将下载文档到 ~/.clawtools/docs',
    'search.cloneProgress': '正在克隆 OpenClaw 文档...',
    'search.success': '文档克隆并索引成功！',
    'search.failed': '文档克隆失败',
    'search.query': '搜索查询',
    'search.results': '找到 {count} 个结果',
    'search.noResults': '未找到 "{query}" 的结果',
    'search.pressEnter': '输入查询并按 [Enter] 搜索',

    // Common
    'common.loading': '加载中...',
    'common.error': '错误',
    'common.success': '成功',
    'common.warning': '警告',
    'common.info': '信息',
    'common.yes': '是',
    'common.no': '否',
    'common.cancel': '取消',
    'common.confirm': '确认',
    'common.back': '返回',
    'common.quit': '退出',
  },
  'en': {
    // App
    'app.title': 'ClawTools',
    'app.subtitle': 'OpenClaw Management Suite',
    'app.platform': 'Platform',
    'app.nodejs': 'Node.js',
    'app.openclaw': 'OpenClaw',
    'app.notInstalled': 'Not installed',
    'app.version': 'Version',

    // Menu
    'menu.select': 'Select an option',
    'menu.exit': 'Exit',
    'menu.exitHint': 'Press [q] to exit • Press number to select',

    // Install
    'install.title': 'Install OpenClaw',
    'install.selectChannel': 'Select version channel',
    'install.channel.stable': 'Stable',
    'install.channel.stableDesc': 'Latest stable release (recommended)',
    'install.channel.beta': 'Beta',
    'install.channel.betaDesc': 'Pre-release with new features',
    'install.channel.dev': 'Dev',
    'install.channel.devDesc': 'Development build (unstable)',
    'install.pressNumber': 'Press [1/2/3] to select, [Enter] to install',
    'install.installing': 'Installing...',
    'install.success': 'Installation successful!',
    'install.failed': 'Installation failed',
    'install.pressKey': 'Press any key to continue',

    // Config
    'config.title': 'Provider Configuration',
    'config.selectProvider': 'Select a provider to configure',
    'config.enterApiKey': 'Enter API Key (press Enter to save)',
    'config.saved': 'API Key saved',
    'config.configured': 'configured',
    'config.pressNumber': 'Press [1-{n}] to select, [q] to quit',

    // Doctor
    'doctor.title': 'OpenClaw Diagnostics',
    'doctor.running': 'Running diagnostics...',
    'doctor.summary': 'Summary',
    'doctor.passed': 'passed',
    'doctor.warnings': 'warnings',
    'doctor.errors': 'errors',
    'doctor.fix': 'Fix',
    'doctor.timestamp': 'Timestamp',
    'doctor.pressEnter': 'Press [Enter] to run openclaw doctor, [Esc] to go back',

    // Backup
    'backup.title': 'Backup & Restore',
    'backup.create': 'Create Backup',
    'backup.restore': 'Restore Backup',
    'backup.noBackups': 'No backups found',
    'backup.creating': 'Creating backup...',
    'backup.restoring': 'Restoring backup...',
    'backup.success': 'Operation successful',
    'backup.failed': 'Operation failed',
    'backup.pressKey': 'Press [1] create, [2] restore, [Esc] go back',
    'backup.recent': 'Recent backups',

    // Search
    'search.title': 'Documentation Search',
    'search.clone': 'Clone Documentation',
    'search.cloneHint': 'This will download docs to ~/.clawtools/docs',
    'search.cloneProgress': 'Cloning OpenClaw documentation...',
    'search.success': 'Documentation cloned and indexed successfully!',
    'search.failed': 'Failed to clone documentation',
    'search.query': 'Search query',
    'search.results': 'Found {count} result(s)',
    'search.noResults': 'No results found for "{query}"',
    'search.pressEnter': 'Type your query and press [Enter] to search',

    // Common
    'common.loading': 'Loading...',
    'common.error': 'Error',
    'common.success': 'Success',
    'common.warning': 'Warning',
    'common.info': 'Info',
    'common.yes': 'Yes',
    'common.no': 'No',
    'common.cancel': 'Cancel',
    'common.confirm': 'Confirm',
    'common.back': 'Back',
    'common.quit': 'Quit',
  },
};

export function t(key: keyof TranslationKeys, locale: Locale = defaultLocale, params?: Record<string, string | number>): string {
  const translation = translations[locale]?.[key] || translations[defaultLocale]?.[key] || key;

  if (!params) {
    return translation;
  }

  return Object.entries(params).reduce((str, [k, v]) => {
    return str.replace(new RegExp(`\\{${k}\\}`, 'g'), String(v));
  }, translation);
}

export function getLocale(): Locale {
  const envLocale = process.env.CLAWTOOLS_LOCALE as Locale;
  if (envLocale && supportedLocales.some(l => l.code === envLocale)) {
    return envLocale;
  }

  const lang = process.env.LANG || process.env.LC_ALL || '';
  if (lang.startsWith('zh')) {
    return 'zh-CN';
  }

  return 'en';
}

export function setLocale(locale: Locale): void {
  process.env.CLAWTOOLS_LOCALE = locale;
}

export class I18n {
  private locale: Locale;

  constructor(locale?: Locale) {
    this.locale = locale || getLocale();
  }

  public translate(key: keyof TranslationKeys, params?: Record<string, string | number>): string {
    return t(key, this.locale, params);
  }

  public setLocale(locale: Locale): void {
    this.locale = locale;
    setLocale(locale);
  }

  public getLocale(): Locale {
    return this.locale;
  }
}

export const i18n = new I18n();
