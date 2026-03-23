import { describe, it, expect } from 'vitest';
import {
  Doctor,
  doctor,
  type DiagnosticItem,
  type DiagnosticResult,
  type DiagnosticLevel
} from '../../core/doctor';

describe('doctor', () => {
  describe('DiagnosticLevel', () => {
    it('should have info level', () => {
      const level: DiagnosticLevel = 'info';
      expect(level).toBe('info');
    });

    it('should have warn level', () => {
      const level: DiagnosticLevel = 'warn';
      expect(level).toBe('warn');
    });

    it('should have error level', () => {
      const level: DiagnosticLevel = 'error';
      expect(level).toBe('error');
    });

    it('should have success level', () => {
      const level: DiagnosticLevel = 'success';
      expect(level).toBe('success');
    });
  });

  describe('DiagnosticItem structure', () => {
    it('should accept valid diagnostic item', () => {
      const item: DiagnosticItem = {
        id: 'test-item',
        name: 'Test Item',
        description: 'A test diagnostic item',
        status: 'pass',
        message: 'Test passed',
        level: 'success'
      };
      expect(item.id).toBe('test-item');
      expect(item.status).toBe('pass');
      expect(item.level).toBe('success');
    });

    it('should accept item with optional fix', () => {
      const item: DiagnosticItem = {
        id: 'test-item',
        name: 'Test Item',
        description: 'A test item',
        status: 'fail',
        message: 'Test failed',
        level: 'error',
        fix: 'Run this command to fix'
      };
      expect(item.fix).toBe('Run this command to fix');
    });
  });

  describe('DiagnosticResult structure', () => {
    it('should accept valid diagnostic result', () => {
      const result: DiagnosticResult = {
        items: [
          { id: 'test', name: 'Test', description: 'test', status: 'pass', message: 'OK', level: 'success' }
        ],
        summary: { total: 1, passed: 1, warnings: 0, errors: 0 },
        timestamp: new Date().toISOString()
      };
      expect(result.items.length).toBe(1);
      expect(result.summary.passed).toBe(1);
    });

    it('should accept result with warnings', () => {
      const result: DiagnosticResult = {
        items: [
          { id: 'test', name: 'Test', description: 'test', status: 'warning', message: 'Warning', level: 'warn' }
        ],
        summary: { total: 1, passed: 0, warnings: 1, errors: 0 },
        timestamp: new Date().toISOString()
      };
      expect(result.summary.warnings).toBe(1);
    });
  });

  describe('Doctor class', () => {
    it('should be instantiable', () => {
      const d = new Doctor();
      expect(d).toBeDefined();
    });

    it('should have run method', () => {
      const d = new Doctor();
      expect(typeof d.run).toBe('function');
    });

    it('run should return DiagnosticResult', async () => {
      const d = new Doctor();
      const result = await d.run();
      expect(result).toHaveProperty('items');
      expect(result).toHaveProperty('summary');
      expect(result).toHaveProperty('timestamp');
    });
  });

  describe('doctor singleton', () => {
    it('should be a Doctor instance', () => {
      expect(doctor).toBeDefined();
      expect(doctor instanceof Doctor).toBe(true);
    });

    it('should have run method', () => {
      expect(typeof doctor.run).toBe('function');
    });

    it('run should return DiagnosticResult', async () => {
      const result = await doctor.run();
      expect(result).toHaveProperty('items');
      expect(result).toHaveProperty('summary');
      expect(result).toHaveProperty('timestamp');
    });
  });
});