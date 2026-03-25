#!/usr/bin/env node
// Fix ESM import statements to include .js extensions
// Required for Node.js native ESM module resolution
// ONLY fixes relative imports (starting with . or ..), NOT bare module names

import fg from 'fast-glob';
const { glob } = fg;
import { readFileSync, writeFileSync } from 'fs';
import { relative } from 'path';

const outDir = './bin';

async function fixImports() {
  const files = await glob(`${outDir}/**/*.js`, { absolute: false });

  for (const file of files) {
    let content = readFileSync(file, 'utf-8');
    let modified = false;

    // Fix relative imports without extensions (MUST start with . or ..)
    // Matches: from './foo', from '../foo', from '../../foo', etc.
    // Does NOT match: node_modules imports, bare module names like 'react', 'ink'
    const importRegex = /(from\s+['"])(\.{1,2}[/\\][^'"]+)([^'".\s]*)(['"])/g;

    content = content.replace(importRegex, (match, quoteStart, relPath, moduleSuffix, quoteEnd) => {
      // relPath already contains the full relative path including ./ or ../
      // moduleSuffix is empty for bare module names like 'react'
      // We only want to add .js to paths that look like relative paths

      // Skip if it ends with a file extension already
      if (moduleSuffix.includes('.')) {
        return match;
      }

      // relPath should end with a directory or be like ./ or ../
      // Check if this is a bare module (doesn't start with .)
      const fullPath = relPath + moduleSuffix;
      if (!fullPath.startsWith('.') && !fullPath.startsWith('/')) {
        return match;
      }

      // Skip node_modules
      if (fullPath.includes('node_modules')) {
        return match;
      }

      // Add .js extension only if it doesn't already have one
      if (!moduleSuffix) {
        // No suffix means the path ends with the module name
        // Add .js
        modified = true;
        return `${quoteStart}${relPath}.js${quoteEnd}`;
      }

      return match;
    });

    // Also fix require statements with relative paths
    const requireRegex = /(require\(['"])(\.{1,2}[/\\][^'"]+)([^'".\s]*)(['"]\))/g;
    content = content.replace(requireRegex, (match, requireStart, relPath, moduleSuffix, quoteEnd) => {
      const fullPath = relPath + moduleSuffix;
      if (!fullPath.startsWith('.') && !fullPath.startsWith('/')) {
        return match;
      }
      if (fullPath.includes('node_modules')) {
        return match;
      }
      if (moduleSuffix && !moduleSuffix.includes('.')) {
        modified = true;
        return `${requireStart}${relPath}${moduleSuffix}.js${quoteEnd}`;
      }
      if (!moduleSuffix) {
        modified = true;
        return `${requireStart}${relPath}.js${quoteEnd}`;
      }
      return match;
    });

    if (modified) {
      writeFileSync(file, content, 'utf-8');
      console.log(`Fixed: ${relative(outDir, file)}`);
    }
  }

  console.log(`\nFixed imports in ${files.length} files`);
}

fixImports().catch(console.error);
