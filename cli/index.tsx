#!/usr/bin/env node

import React from 'react';
import { render } from 'ink';
import chalk from 'chalk';
import { App } from './App';
import { detectSystem } from '../core/detector';

const systemInfo = detectSystem();

console.log(chalk.blue('╔═══════════════════════════════════════════════╗'));
console.log(chalk.blue('║           ') + chalk.bold.white('ClawTools') + chalk.blue('                          ║'));
console.log(chalk.blue('║       OpenClaw Management Suite v0.1.0       ║'));
console.log(chalk.blue('╚═══════════════════════════════════════════════╝'));
console.log();

const instance = render(React.createElement(App, { systemInfo }));

process.on('SIGINT', () => {
  console.log(chalk.yellow('\n\nShutting down...'));
  instance.unmount();
  process.exit(0);
});
