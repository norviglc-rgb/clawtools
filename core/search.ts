import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { execSync } from 'child_process';
import FlexSearch from 'flexsearch';

export interface DocIndex {
  id: string;
  title: string;
  path: string;
  content: string;
  url?: string;
}

export interface SearchResult {
  id: string;
  title: string;
  path: string;
  snippet: string;
  score: number;
}

export class DocSearch {
  private index: any;
  private docs: Map<string, DocIndex>;
  private docsDir: string;

  constructor(docsDir?: string) {
    this.index = new FlexSearch.Document({
      document: {
        id: 'id',
        index: ['title', 'content'],
        store: ['title', 'path', 'content'],
      },
      tokenize: 'forward',
      resolution: 9,
    });

    this.docs = new Map();
    this.docsDir = docsDir || path.join(os.homedir(), '.clawtools', 'docs');
  }

  public getDocsDir(): string {
    return this.docsDir;
  }

  public async cloneDocs(): Promise<boolean> {
    const repoUrl = 'https://github.com/openclaw/openclaw.git';
    const branch = 'main';

    try {
      if (fs.existsSync(this.docsDir)) {
        console.log('Docs already exist, pulling latest...');
        execSync('git fetch origin', { cwd: this.docsDir, stdio: 'ignore' });
        execSync(`git checkout ${branch}`, { cwd: this.docsDir, stdio: 'ignore' });
        execSync('git pull', { cwd: this.docsDir, stdio: 'inherit' });
      } else {
        console.log('Cloning OpenClaw docs...');
        const parentDir = path.dirname(this.docsDir);
        if (!fs.existsSync(parentDir)) {
          fs.mkdirSync(parentDir, { recursive: true });
        }
        execSync(`git clone --depth 1 --branch ${branch} ${repoUrl} "${this.docsDir}"`, { stdio: 'inherit' });
      }

      return true;
    } catch (error: any) {
      console.error('Failed to clone docs:', error.message);
      return false;
    }
  }

  public async buildIndex(): Promise<boolean> {
    try {
      const docsPath = path.join(this.docsDir, 'docs');
      if (!fs.existsSync(docsPath)) {
        console.error('Docs directory not found:', docsPath);
        return false;
      }

      const mdFiles = this.walkDir(docsPath, '.md');

      for (const file of mdFiles) {
        await this.indexFile(file);
      }

      console.log(`Indexed ${this.docs.size} documents`);
      return true;
    } catch (error: any) {
      console.error('Failed to build index:', error.message);
      return false;
    }
  }

  private walkDir(dir: string, extension: string): string[] {
    const results: string[] = [];

    if (!fs.existsSync(dir)) {
      return results;
    }

    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        if (!entry.name.startsWith('.') && entry.name !== 'node_modules') {
          results.push(...this.walkDir(fullPath, extension));
        }
      } else if (entry.name.endsWith(extension)) {
        results.push(fullPath);
      }
    }

    return results;
  }

  private async indexFile(filePath: string): Promise<void> {
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const relativePath = path.relative(this.docsDir, filePath);
      const id = this.normalizeId(relativePath);

      const title = this.extractTitle(content, relativePath);
      const cleanContent = this.cleanContent(content);

      const docIndex: DocIndex = {
        id,
        title,
        path: relativePath,
        content: cleanContent,
      };

      this.docs.set(id, docIndex);

      this.index.add({
        id,
        title,
        content: cleanContent,
        path: relativePath,
      });
    } catch (error) {
      console.error(`Failed to index file ${filePath}:`, error);
    }
  }

  private normalizeId(filePath: string): string {
    return filePath.replace(/[/\\:]/g, '-').replace(/\.md$/, '');
  }

  private extractTitle(content: string, filePath: string): string {
    const lines = content.split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
    }
    return path.basename(filePath, '.md');
  }

  private cleanContent(content: string): string {
    return content
      .replace(/```[\s\S]*?```/g, '')
      .replace(/`[^`]+`/g, '')
      .replace(/#{1,6}\s+/g, '')
      .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
      .replace(/[*_~]/g, '')
      .replace(/\n+/g, ' ')
      .trim()
      .substring(0, 10000);
  }

  public search(query: string, limit: number = 10): SearchResult[] {
    try {
      const results = this.index.search(query, {
        limit,
        enrich: true,
      });

      const searchResults: SearchResult[] = [];

      if (results && results.length > 0) {
        for (const result of results) {
          if (result.result && Array.isArray(result.result)) {
            for (const item of result.result) {
              const doc = this.docs.get(item.id);
              if (doc) {
                searchResults.push({
                  id: doc.id,
                  title: doc.title,
                  path: doc.path,
                  snippet: this.createSnippet(doc.content, query),
                  score: 1,
                });
              }
            }
          }
        }
      }

      return searchResults.slice(0, limit);
    } catch (error) {
      console.error('Search failed:', error);
      return [];
    }
  }

  private createSnippet(content: string, query: string, contextLength: number = 150): string {
    const lowerContent = content.toLowerCase();
    const lowerQuery = query.toLowerCase();
    const index = lowerContent.indexOf(lowerQuery);

    if (index === -1) {
      return content.substring(0, contextLength) + '...';
    }

    const start = Math.max(0, index - contextLength / 2);
    const end = Math.min(content.length, index + query.length + contextLength / 2);

    let snippet = content.substring(start, end);
    if (start > 0) snippet = '...' + snippet;
    if (end < content.length) snippet = snippet + '...';

    return snippet;
  }

  public saveIndex(): boolean {
    try {
      const indexPath = path.join(os.homedir(), '.clawtools', 'doc-index.json');
      const data = {
        docs: Array.from(this.docs.entries()),
      };
      fs.writeFileSync(indexPath, JSON.stringify(data), 'utf8');
      return true;
    } catch {
      return false;
    }
  }

  public loadIndex(): boolean {
    try {
      const indexPath = path.join(os.homedir(), '.clawtools', 'doc-index.json');
      if (!fs.existsSync(indexPath)) {
        return false;
      }

      const data = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
      this.docs = new Map(data.docs);

      for (const [id, doc] of this.docs) {
        this.index.add({
          id,
          title: doc.title,
          content: doc.content,
          path: doc.path,
        });
      }

      return true;
    } catch {
      return false;
    }
  }

  public getDocById(id: string): DocIndex | undefined {
    return this.docs.get(id);
  }

  public getDocByPath(relativePath: string): DocIndex | undefined {
    const normalizedPath = relativePath.replace(/\\/g, '/');
    for (const doc of this.docs.values()) {
      if (doc.path.replace(/\\/g, '/') === normalizedPath) {
        return doc;
      }
    }
    return undefined;
  }
}
