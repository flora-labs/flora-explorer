#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Get package version
const packageJson = require('../package.json');

// Get git info
let gitHash = 'unknown';
let gitBranch = 'unknown';
try {
  gitHash = execSync('git rev-parse --short HEAD').toString().trim();
  gitBranch = execSync('git rev-parse --abbrev-ref HEAD').toString().trim();
} catch (e) {
  console.warn('Warning: Git info not available');
}

// Generate version info
const versionInfo = {
  version: packageJson.version,
  gitHash: gitHash,
  gitBranch: gitBranch,
  buildTime: new Date().toISOString(),
  deployTime: new Date().toISOString()
};

// Write to public directory
const outputPath = path.join(__dirname, '../public/version.json');
fs.writeFileSync(outputPath, JSON.stringify(versionInfo, null, 2));

console.log('✅ Version info generated:', versionInfo);