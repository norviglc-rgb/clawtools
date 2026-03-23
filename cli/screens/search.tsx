import React, { useState, useEffect } from 'react';
import { Box, Text } from 'ink';
import { DocSearch, SearchResult } from '../../core/search';
import { getDatabase } from '../../db';

type SearchStep = 'menu' | 'searching' | 'results';

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
    setMessage('Cloning OpenClaw documentation...');
    setStep('searching');

    const success = await docSearch.cloneDocs();

    if (success) {
      await docSearch.buildIndex();
      docSearch.saveIndex();
      db.updateAppConfig({ docsCloned: true, docsCloneDate: new Date().toISOString() });
      setMessage('Documentation cloned and indexed successfully!');
      setNeedsClone(false);
    } else {
      setMessage('Failed to clone documentation');
    }

    setStep('done');
  };

  const handleSearch = () => {
    if (!query.trim()) {
      setMessage('Please enter a search query');
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
      <Text bold>Documentation Search</Text>
      <Box marginY={1}>
        <Text dimColor>─────────────────────────────────────</Text>
      </Box>

      {needsClone && step === 'menu' && (
        <>
          <Text>OpenClaw documentation needs to be cloned first.</Text>
          <Box marginY={1}>
            <Text dimColor>This will download the docs to ~/.clawtools/docs</Text>
          </Box>
          <Box marginTop={1}>
            <Text>Press [Enter] to clone documentation</Text>
          </Box>
        </>
      )}

      {!needsClone && step === 'menu' && (
        <>
          <Box marginBottom={1}>
            <Text>Search query:</Text>
          </Box>
          <Box>
            <Text>> {query}</Text>
            <Text dimColor> █</Text>
          </Box>
          <Box marginTop={1}>
            <Text dimColor>Type your query and press [Enter] to search</Text>
          </Box>
        </>
      )}

      {step === 'searching' && (
        <Text>{message || 'Processing...'}</Text>
      )}

      {step === 'done' && (
        <>
          <Text>{message}</Text>
          <Box marginTop={1}>
            <Text dimColor>Press any key to continue</Text>
          </Box>
        </>
      )}

      {step === 'results' && (
        <>
          {results.length > 0 ? (
            <>
              <Text marginBottom={1}>
                Found {results.length} result(s):
              </Text>
              {results.map((result, index) => (
                <Box key={result.id} marginBottom={1} flexDirection="column">
                  <Box flexDirection="row">
                    <Text dimColor width={2}>{index + 1}.</Text>
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
            <Text>No results found for "{query}"</Text>
          )}
          <Box marginTop={1}>
            <Text dimColor>Press any key to search again</Text>
          </Box>
        </>
      )}

      <Box marginTop={1}>
        <Text dimColor>Press [Esc] to go back</Text>
      </Box>
    </Box>
  );
}
