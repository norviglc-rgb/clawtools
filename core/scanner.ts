import { exec } from 'child_process';
import * as net from 'net';

export interface ScanAuthorization {
  granted: boolean;
  timestamp: string | null;
  scanType: 'none' | 'local' | 'network';
}

export interface PortScanResult {
  port: number;
  service: string;
  status: 'open' | 'closed' | 'filtered';
}

export interface SecurityScanResult {
  authorized: ScanAuthorization;
  firewall: {
    enabled: boolean;
    platform: string;
  };
  ports: PortScanResult[];
  securityIssues: SecurityIssue[];
  timestamp: string;
}

export interface SecurityIssue {
  id: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  title: string;
  description: string;
  recommendation: string;
}

const COMMON_PORTS: { port: number; service: string }[] = [
  { port: 21, service: 'FTP' },
  { port: 22, service: 'SSH' },
  { port: 23, service: 'Telnet' },
  { port: 25, service: 'SMTP' },
  { port: 53, service: 'DNS' },
  { port: 80, service: 'HTTP' },
  { port: 110, service: 'POP3' },
  { port: 143, service: 'IMAP' },
  { port: 443, service: 'HTTPS' },
  { port: 465, service: 'SMTPS' },
  { port: 587, service: 'SMTP-TLS' },
  { port: 993, service: 'IMAPS' },
  { port: 995, service: 'POP3S' },
  { port: 3000, service: 'Web UI' },
  { port: 3306, service: 'MySQL' },
  { port: 5432, service: 'PostgreSQL' },
  { port: 6379, service: 'Redis' },
  { port: 8080, service: 'HTTP-Alt' },
  { port: 8443, service: 'HTTPS-Alt' },
  { port: 18789, service: 'OpenClaw Gateway' },
  { port: 27017, service: 'MongoDB' },
];

const DANGEROUS_PORTS: Record<number, SecurityIssue> = {
  23: {
    id: 'danger-telnet',
    severity: 'critical',
    title: 'Telnet Port Open',
    description: 'Telnet is running on port 23. Telnet transmits data including passwords in plain text.',
    recommendation: 'Disable Telnet and use SSH instead.',
  },
  21: {
    id: 'danger-ftp',
    severity: 'high',
    title: 'FTP Port Open',
    description: 'FTP is running on port 21. FTP transmits credentials in plain text.',
    recommendation: 'Use SFTP or FTPS instead.',
  },
};

export class SecurityScanner {
  private authorization: ScanAuthorization = {
    granted: false,
    timestamp: null,
    scanType: 'none',
  };

  requestAuthorization(scanType: 'local' | 'network' = 'local'): boolean {
    this.authorization = {
      granted: true,
      timestamp: new Date().toISOString(),
      scanType,
    };
    return true;
  }

  revokeAuthorization(): void {
    this.authorization = {
      granted: false,
      timestamp: null,
      scanType: 'none',
    };
  }

  isAuthorized(): boolean {
    return this.authorization.granted;
  }

  getAuthorization(): ScanAuthorization {
    return { ...this.authorization };
  }

  private async checkFirewallStatus(): Promise<{ enabled: boolean; platform: string }> {
    return new Promise((resolve) => {
      const platform = process.platform;

      if (platform === 'win32') {
        exec('netsh advfirewall show allprofiles state', { encoding: 'utf8' }, (err, stdout) => {
          if (err) {
            resolve({ enabled: false, platform: 'windows' });
            return;
          }
          const enabled = stdout.includes('ON');
          resolve({ enabled, platform: 'windows' });
        });
      } else if (platform === 'darwin') {
        exec('defaults read /Library/Application\\ Support/com.apple.alf/globalstate', { encoding: 'utf8' }, (err) => {
          resolve({ enabled: !err, platform: 'macos' });
        });
      } else {
        exec('ufw status', { encoding: 'utf8' }, (err, stdout) => {
          if (err) {
            resolve({ enabled: false, platform: 'linux' });
            return;
          }
          const enabled = stdout.includes('active');
          resolve({ enabled, platform: 'linux' });
        });
      }
    });
  }

  private async scanPort(port: number, timeout: number = 1000): Promise<PortScanResult> {
    const portInfo = COMMON_PORTS.find((p) => p.port === port);
    const service = portInfo?.service || 'Unknown';

    return new Promise((resolve) => {
      const client = new net.Socket();

      client.setTimeout(timeout, () => {
        client.destroy();
        resolve({ port, service, status: 'filtered' });
      });

      client.connect(port, '127.0.0.1', () => {
        client.destroy();
        resolve({ port, service, status: 'open' });
      });

      client.on('error', () => {
        client.destroy();
        resolve({ port, service, status: 'closed' });
      });
    });
  }

  private async scanPorts(ports: number[]): Promise<PortScanResult[]> {
    const results: PortScanResult[] = [];
    for (const port of ports) {
      const result = await this.scanPort(port);
      results.push(result);
    }
    return results;
  }

  private identifySecurityIssues(ports: PortScanResult[]): SecurityIssue[] {
    const issues: SecurityIssue[] = [];

    for (const port of ports) {
      if (port.status === 'open' && DANGEROUS_PORTS[port.port]) {
        issues.push(DANGEROUS_PORTS[port.port]);
      }
    }

    return issues;
  }

  async runLocalScan(): Promise<SecurityScanResult> {
    if (!this.isAuthorized()) {
      return {
        authorized: this.authorization,
        firewall: { enabled: false, platform: 'unknown' },
        ports: [],
        securityIssues: [],
        timestamp: new Date().toISOString(),
      };
    }

    const firewall = await this.checkFirewallStatus();
    const portsToScan = COMMON_PORTS.map((p) => p.port);
    const portResults = await this.scanPorts(portsToScan);
    const securityIssues = this.identifySecurityIssues(portResults);

    return {
      authorized: this.authorization,
      firewall,
      ports: portResults.filter((p) => p.status === 'open'),
      securityIssues,
      timestamp: new Date().toISOString(),
    };
  }

  async scanSinglePort(port: number): Promise<PortScanResult> {
    if (!this.isAuthorized()) {
      return { port, service: 'Unknown', status: 'closed' };
    }
    return this.scanPort(port);
  }
}

export const scanner = new SecurityScanner();
