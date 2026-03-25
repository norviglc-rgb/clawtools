import React, { useState, useEffect } from 'react';
import { Box, Text } from 'ink';
import { DocSearch, SearchResult } from '../../core/search';
import { getDatabase } from '../../db/index';

type SearchStep = 'menu' | 'searching' | 'results' | 'done';

export function SearchScreen() {
  const [step, setStep] = useState<SearchStep>('menu');
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [message, setMessage] = useState('');
  const [needsClone, setNeedsClone] = useState(false);

  const db = getDatabase();
  const docSearch = new DocSearch();

  useEffect(() => {
    const config = db.getAppConfig();
    setNeedsClone(!config.docsCloned);
  }, []);

  const handleCloneDocs = async () => {
    setMessage('正在克隆 OpenClaw 文档...');
    setStep('searching');

    const success = await docSearch.cloneDocs();

    if (success) {
      await docSearch.buildIndex();
      docSearch.saveIndex();
      db.updateAppConfig({ docsCloned: true, docsCloneDate: new Date().toISOString() });
      setMessage('文档克隆和索引成功!');
      setNeedsClone(false);
    } else {
      setMessage('克隆文档失败');
    }

    setStep('done');
  };

  const handleSearch = () => {
    if (!query.trim()) {
      setMessage('请输入搜索查询');
      return;
    }

    setStep('searching');
    const searchResults = docSearch.search(query, 10);
    setResults(searchResults);
    setStep('results');
  };

  useEffect(() => {
    const handler = (data: Buffer) => {
      const key = data.toString();

      if (step === 'menu' && needsClone) {
        if (key === '\r' || key === '\n') {
          handleCloneDocs();
        }
      } else if (step === 'menu') {
        if (key === '\r' || key === '\n') {
          handleSearch();
        } else if (key === '\x7f') {
          setQuery(prev => prev.slice(0, -1));
        } else if (key.length === 1) {
          setQuery(prev => prev + key);
        }
      } else if (step === 'done') {
        if (key === '\r' || key === '\n' || key === '\x1b') {
          setStep(needsClone ? 'menu' : 'results');
          setMessage('');
        }
      } else if (step === 'results') {
        if (key === '\r' || key === '\n' || key === '\x1b') {
          setStep('menu');
          setQuery('');
          setResults([]);
        }
      }
    };

    process.stdin.setRawMode(true);
    process.stdin.on('data', handler);

    return () => {
      process.stdin.setRawMode(false);
      process.stdin.removeAllListeners('data');
    };
  }, [step, query, needsClone]);

  return (
    <Box flexDirection="column" padding={1}>
      <Text bold>文档搜索</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>

      {needsClone && step === 'menu' && (
        <>
          <Text>需要先克隆 OpenClaw 文档。</Text>
          <Box marginY={1}>
            <Text dimColor>这会将文档下载到 ~/.clawtools/docs</Text>
          </Box>
          <Box marginTop={1}>
            <Text>按 [回车] 克隆文档</Text>
          </Box>
        </>
      )}

      {!needsClone && step === 'menu' && (
        <>
          <Box marginBottom={1}>
            <Text>搜索查询:</Text>
          </Box>
          <Box>
            <Text>{'>'} {query}</Text>
            <Text dimColor> █</Text>
          </Box>
          <Box marginTop={1}>
            <Text dimColor>输入查询后按 [回车] 搜索</Text>
          </Box>
        </>
      )}

      {step === 'searching' && (
        <Text>{message || '处理中...'}</Text>
      )}

      {step === 'done' && (
        <>
          <Text>{message}</Text>
          <Box marginTop={1}>
            <Text dimColor>按任意键继续</Text>
          </Box>
        </>
      )}

      {step === 'results' && (
        <>
          {results.length > 0 ? (
            <>
              <Box marginBottom={1}>
                <Text>
                  找到 {results.length} 个结果:
                </Text>
              </Box>
              {results.map((result, index) => (
                <Box key={result.id} marginBottom={1} flexDirection="column">
                  <Box flexDirection="row">
                    <Box width={2}>
                      <Text dimColor>{index + 1}.</Text>
                    </Box>
                    <Text bold color="cyan">{result.title}</Text>
                  </Box>
                  <Box paddingLeft={3} flexDirection="column">
                    <Text dimColor>{result.path}</Text>
                    <Text>{result.snippet}</Text>
                  </Box>
                </Box>
              ))}
            </>
          ) : (
            <Text>没有找到 "{query}" 的结果</Text>
          )}
          <Box marginTop={1}>
            <Text dimColor>按任意键继续搜索</Text>
          </Box>
        </>
      )}

      <Box marginTop={1}>
        <Text dimColor>按 [Esc] 返回</Text>
      </Box>
    </Box>
  );
}
