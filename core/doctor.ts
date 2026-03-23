import { execSync, exec } from 'child_process';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';
import { detectSystem, checkFirewall, checkPublicIP, detectPorts, SystemInfo } from './detector';

export type DiagnosticLevel = 'info' | 'warn' | 'error' | 'success';

export interface DiagnosticItem {
  id: string;
  name: string;
  description: string;
  level: DiagnosticLevel;
  status: 'pass' | 'fail' | 'warning' | 'info';
  message: string;
  fix?: string;
}

export interface DiagnosticResult {
  items: DiagnosticItem[];
  summary: {
    total: number;
    passed: number;
    warnings: number;
    errors: number;
  };
  timestamp: string;
}

export class Doctor {
  private items: DiagnosticItem[] = [];

  async run(): Promise<DiagnosticResult> {
    this.items = [];

    await this.checkNode();
    await this.checkOpenClaw();
    await this.checkGateway();
    await this.checkFirewall();
    await this.checkPublicIP();
    await this.checkPorts();
    await this.checkEnvironment();

    return this.getResult();
  }

  private async checkNode(): Promise<void> {
    try {
      const version = execSync('node --version', { encoding: 'utf8' }).trim();
      const semver = require('semver');

      if (!semver.gte(version, '20.0.0')) {
        this.addItem({
          id: 'node-version',
          name: 'Node.js Version',
          description: 'Node.js version should be >= 20.0.0',
          level: 'error',
          status: 'fail',
          message: `Node.js ${version} is too old. Please upgrade to Node.js 20+.`,
          fix: 'Run: npm install -g n && n latest',
        });
      } else {
        this.addItem({
          id: 'node-version',
          name: 'Node.js Version',
          description: 'Node.js version should be >= 20.0.0',
          level: 'success',
          status: 'pass',
          message: `Node.js ${version} is up to date`,
        });
      }
    } catch {
      this.addItem({
        id: 'node-installed',
        name: 'Node.js Installation',
        description: 'Node.js should be installed',
        level: 'error',
        status: 'fail',
        message: 'Node.js is not installed',
        fix: 'Run: curl -fsSL https://nodejs.org/install.sh | bash',
      });
    }
  }

  private async checkOpenClaw(): Promise<void> {
    try {
      const version = execSync('openclaw --version', { encoding: 'utf8', stdio: 'pipe' }).trim();
      this.addItem({
        id: 'openclaw-installed',
        name: 'OpenClaw Installation',
        description: 'OpenClaw CLI should be installed',
        level: 'success',
        status: 'pass',
        message: `OpenClaw ${version} is installed`,
      });
    } catch {
      this.addItem({
        id: 'openclaw-installed',
        name: 'OpenClaw Installation',
        description: 'OpenClaw CLI should be installed',
        level: 'error',
        status: 'fail',
        message: 'OpenClaw is not installed',
        fix: 'Run: npm install -g openclaw@latest',
      });
    }
  }

  private async checkGateway(): Promise<void> {
    try {
      const output = execSync('openclaw gateway status', { encoding: 'utf8', stdio: 'pipe' });
      if (output.includes('running') || output.includes('active')) {
        this.addItem({
          id: 'gateway-running',
          name: 'OpenClaw Gateway',
          description: 'OpenClaw Gateway should be running',
          level: 'success',
          status: 'pass',
          message: 'OpenClaw Gateway is running',
        });
      } else {
        this.addItem({
          id: 'gateway-running',
          name: 'OpenClaw Gateway',
          description: 'OpenClaw Gateway should be running',
          level: 'warn',
          status: 'warning',
          message: 'OpenClaw Gateway may not be running',
          fix: 'Run: openclaw gateway start',
        });
      }
    } catch {
      this.addItem({
        id: 'gateway-running',
        name: 'OpenClaw Gateway',
        description: 'OpenClaw Gateway should be running',
        level: 'warn',
        status: 'warning',
        message: 'Could not check Gateway status',
        fix: 'Run: openclaw gateway start',
      });
    }
  }

  private async checkFirewall(): Promise<void> {
    const firewall = await checkFirewall();

    if (process.platform === 'win32' || process.platform === 'linux') {
      if (firewall.enabled) {
        this.addItem({
          id: 'firewall',
          name: 'Firewall Status',
          description: 'Firewall configuration check',
          level: 'info',
          status: 'info',
          message: `Firewall is enabled on this system`,
        });
      } else {
        this.addItem({
          id: 'firewall',
          name: 'Firewall Status',
          description: 'Firewall configuration check',
          level: 'warn',
          status: 'warning',
          message: 'Firewall may not be enabled',
          fix: 'Consider enabling firewall for security',
        });
      }
    }
  }

  private async checkPublicIP(): Promise<void> {
    const ip = await checkPublicIP();

    if (ip) {
      this.addItem({
        id: 'public-ip',
        name: 'Public IP Detection',
        description: 'Check if system has public IP',
        level: 'warn',
        status: 'warning',
        message: `System has public IP: ${ip}. Ensure firewall is configured properly.`,
        fix: 'If not expected, review network configuration',
      });
    } else {
      this.addItem({
        id: 'public-ip',
        name: 'Public IP Detection',
        description: 'Check if system has public IP',
        level: 'info',
        status: 'info',
        message: 'No public IP detected or check failed',
      });
    }
  }

  private async checkPorts(): Promise<void> {
    const port18789 = await detectPorts(18789);
    const port3000 = await detectPorts(3000);

    if (port18789) {
      this.addItem({
        id: 'port-18789',
        name: 'Gateway Port (18789)',
        description: 'OpenClaw Gateway port should be available',
        level: 'success',
        status: 'pass',
        message: 'Gateway port 18789 is in use (Gateway may be running)',
      });
    } else {
      this.addItem({
        id: 'port-18789',
        name: 'Gateway Port (18789)',
        description: 'OpenClaw Gateway port should be available',
        level: 'info',
        status: 'info',
        message: 'Gateway port 18789 is available',
      });
    }

    if (port3000) {
      this.addItem({
        id: 'port-3000',
        name: 'Web UI Port (3000)',
        description: 'Web UI port availability',
        level: 'info',
        status: 'info',
        message: 'Port 3000 is in use (Web UI may be running)',
      });
    }
  }

  private async checkEnvironment(): Promise<void> {
    const envVars = ['OPENCLAW_CONFIG_DIR', 'ANTHROPIC_API_KEY', 'OPENAI_API_KEY'];

    for (const varName of envVars) {
      const value = process.env[varName];
      if (value) {
        const displayValue = varName.includes('KEY') ? '[SET]' : value;
        this.addItem({
          id: `env-${varName.toLowerCase()}`,
          name: `Environment: ${varName}`,
          description: `Environment variable ${varName}`,
          level: 'info',
          status: 'info',
          message: `${varName} is set to ${displayValue}`,
        });
      }
    }

    const configDir = path.join(os.homedir(), '.openclaw');
    if (fs.existsSync(configDir)) {
      this.addItem({
        id: 'config-dir',
        name: 'Config Directory',
        description: 'OpenClaw config directory exists',
        level: 'success',
        status: 'pass',
        message: `Config directory exists: ${configDir}`,
      });
    } else {
      this.addItem({
        id: 'config-dir',
        name: 'Config Directory',
        description: 'OpenClaw config directory exists',
        level: 'warn',
        status: 'warning',
        message: `Config directory not found: ${configDir}`,
        fix: 'Run: openclaw setup to initialize configuration',
      });
    }
  }

  private addItem(item: DiagnosticItem): void {
    this.items.push(item);
  }

  private getResult(): DiagnosticResult {
    const summary = {
      total: this.items.length,
      passed: this.items.filter(i => i.status === 'pass').length,
      warnings: this.items.filter(i => i.status === 'warning').length,
      errors: this.items.filter(i => i.status === 'fail').length,
    };

    return {
      items: this.items,
      summary,
      timestamp: new Date().toISOString(),
    };
  }

  async runOpenClawDoctor(): Promise<string> {
    try {
      const output = execSync('openclaw doctor', { encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 });
      return output;
    } catch (error: any) {
      if (error.stdout) {
        return error.stdout;
      }
      return `Failed to run openclaw doctor: ${error.message}`;
    }
  }
}

export const doctor = new Doctor();
