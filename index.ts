export { detectSystem, checkFirewall, checkPublicIP, detectPorts } from './core/detector';
export type { NodeInfo, OpenClawInfo, SystemInfo } from './core/detector';

export { installOpenClaw, installNode, uninstallOpenClaw, getAvailableVersions } from './core/installer';
export type { InstallOptions, InstallResult, InstallChannel, InstallMethod } from './core/installer';

export { Configurator, presetProviders } from './core/configurator';
export type { ProviderConfig, OpenClawConfig } from './core/configurator';

export { Doctor, doctor } from './core/doctor';
export type { DiagnosticItem, DiagnosticResult, DiagnosticLevel } from './core/doctor';

export { BackupManager } from './core/backup';
export type { BackupOptions, BackupResult, RestoreResult, BackupInfo } from './core/backup';

export { DocSearch } from './core/search';
export type { DocIndex, SearchResult } from './core/search';

export { DatabaseManager, getDatabase } from './db';
export type { AppConfig, ProviderRecord, BackupRecord, HistoryRecord } from './db';

export { providerPresets, recommendedConfig, defaultOpenClawConfig } from './config/providers';
export type { ProviderPreset } from './config/providers';

export { exportForMigration, importMigration, getMigrationPlatformConfig, listMigrationPlatforms } from './core/migration';
export type { MigrationPlatform, MigrationManifest, MigrationExportResult, MigrationImportResult, PathMapping, PlatformConfig } from './core/migration';
