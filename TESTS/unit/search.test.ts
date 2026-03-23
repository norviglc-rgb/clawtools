import { describe, it, expect, beforeEach } from 'vitest';
import {
  DocSearch,
  type DocIndex,
  type SearchResult
} from '../../core/search';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';

describe('search', () => {
  const testDocsDir = path.join(os.tmpdir(), 'clawtools-test-docs-' + Date.now());
  let search: DocSearch;

  beforeEach(() => {
    search = new DocSearch(testDocsDir);
  });

  describe('DocSearch', () => {
    it('should be instantiable', () => {
      expect(search).toBeDefined();
    });

    it('should accept custom docsDir', () => {
      const customSearch = new DocSearch('/tmp/custom-docs');
      expect(customSearch).toBeDefined();
    });

    it('should have getDocsDir method', () => {
      expect(typeof search.getDocsDir).toBe('function');
    });

    it('should have cloneDocs method', () => {
      expect(typeof search.cloneDocs).toBe('function');
    });

    it('should have buildIndex method', () => {
      expect(typeof search.buildIndex).toBe('function');
    });

    it('should have search method', () => {
      expect(typeof search.search).toBe('function');
    });

    it('should have saveIndex method', () => {
      expect(typeof search.saveIndex).toBe('function');
    });

    it('should have loadIndex method', () => {
      expect(typeof search.loadIndex).toBe('function');
    });

    it('should have getDocById method', () => {
      expect(typeof search.getDocById).toBe('function');
    });

    it('should have getDocByPath method', () => {
      expect(typeof search.getDocByPath).toBe('function');
    });
  });

  describe('getDocsDir', () => {
    it('should return docs directory path', () => {
      const docsDir = search.getDocsDir();
      expect(typeof docsDir).toBe('string');
      expect(docsDir.length).toBeGreaterThan(0);
    });

    it('should use custom docsDir when provided', () => {
      const customPath = '/tmp/custom-docs-dir';
      const customSearch = new DocSearch(customPath);
      expect(customSearch.getDocsDir()).toBe(customPath);
    });
  });

  describe('search', () => {
    it('should return array', () => {
      const results = search.search('test');
      expect(Array.isArray(results)).toBe(true);
    });

    it('should accept limit parameter', () => {
      const results = search.search('test', 5);
      expect(Array.isArray(results)).toBe(true);
      expect(results.length).toBeLessThanOrEqual(5);
    });

    it('should return SearchResult objects', () => {
      const results = search.search('test');
      results.forEach(result => {
        expect(result).toHaveProperty('id');
        expect(result).toHaveProperty('title');
        expect(result).toHaveProperty('path');
        expect(result).toHaveProperty('snippet');
        expect(result).toHaveProperty('score');
      });
    });
  });

  describe('DocIndex interface', () => {
    it('should have required properties', () => {
      const index: DocIndex = {
        id: 'test-id',
        title: 'Test Title',
        path: 'test/path.md',
        content: 'Test content'
      };
      expect(index.id).toBe('test-id');
      expect(index.title).toBe('Test Title');
      expect(index.path).toBe('test/path.md');
      expect(index.content).toBe('Test content');
    });

    it('should accept optional url', () => {
      const index: DocIndex = {
        id: 'test-id',
        title: 'Test',
        path: 'test.md',
        content: 'content',
        url: 'https://example.com'
      };
      expect(index.url).toBe('https://example.com');
    });
  });

  describe('SearchResult interface', () => {
    it('should have required properties', () => {
      const result: SearchResult = {
        id: 'result-1',
        title: 'Result Title',
        path: 'result/path.md',
        snippet: 'This is a snippet...',
        score: 0.95
      };
      expect(result.id).toBe('result-1');
      expect(result.title).toBe('Result Title');
      expect(result.path).toBe('result/path.md');
      expect(result.snippet).toBe('This is a snippet...');
      expect(result.score).toBe(0.95);
    });
  });

  describe('getDocById', () => {
    it('should return undefined for nonexistent id', () => {
      const doc = search.getDocById('nonexistent-id');
      expect(doc).toBeUndefined();
    });
  });

  describe('getDocByPath', () => {
    it('should return undefined for nonexistent path', () => {
      const doc = search.getDocByPath('nonexistent/path.md');
      expect(doc).toBeUndefined();
    });
  });

  describe('buildIndex', () => {
    it('should return boolean', async () => {
      // Will fail without real docs but tests interface
      const result = await search.buildIndex();
      expect(typeof result).toBe('boolean');
    });
  });

  describe('cloneDocs', () => {
    it('should return boolean', async () => {
      const result = await search.cloneDocs();
      expect(typeof result).toBe('boolean');
    });
  });

  describe('saveIndex', () => {
    it('should return boolean', () => {
      const result = search.saveIndex();
      expect(typeof result).toBe('boolean');
    });
  });

  describe('loadIndex', () => {
    it('should return boolean', () => {
      const result = search.loadIndex();
      expect(typeof result).toBe('boolean');
    });
  });
});