import { describe, it, expect } from 'vitest';
import {
  DocSearch,
  type DocIndex,
  type SearchResult
} from '../../core/search';

describe('search', () => {
  describe('DocSearch', () => {
    it('should be instantiable', () => {
      const search = new DocSearch();
      expect(search).toBeDefined();
    });

    it('should accept custom docsDir', () => {
      const search = new DocSearch('/tmp/test-docs');
      expect(search).toBeDefined();
    });

    it('should have getDocsDir method', () => {
      const search = new DocSearch();
      expect(typeof search.getDocsDir).toBe('function');
    });

    it('should have cloneDocs method', () => {
      const search = new DocSearch();
      expect(typeof search.cloneDocs).toBe('function');
    });

    it('should have buildIndex method', () => {
      const search = new DocSearch();
      expect(typeof search.buildIndex).toBe('function');
    });

    it('should have search method', () => {
      const search = new DocSearch();
      expect(typeof search.search).toBe('function');
    });

    it('should have saveIndex method', () => {
      const search = new DocSearch();
      expect(typeof search.saveIndex).toBe('function');
    });

    it('should have loadIndex method', () => {
      const search = new DocSearch();
      expect(typeof search.loadIndex).toBe('function');
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
      expect(result.snippet).toBe('This is a snippet...');
      expect(result.score).toBe(0.95);
    });
  });

  describe('search functionality', () => {
    it('should return array of SearchResult', () => {
      const search = new DocSearch();
      const results = search.search('test');
      expect(Array.isArray(results)).toBe(true);
    });

    it('should accept limit parameter', () => {
      const search = new DocSearch();
      const results = search.search('test', 5);
      expect(Array.isArray(results)).toBe(true);
    });
  });

  describe('getDocsDir', () => {
    it('should return a string path', () => {
      const search = new DocSearch();
      const docsDir = search.getDocsDir();
      expect(typeof docsDir).toBe('string');
    });
  });
});