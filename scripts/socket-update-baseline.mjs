#!/usr/bin/env bun
/**
 * Update .github/socket-baseline.json from a SARIF file after a green main scan.
 */

import { readFileSync, writeFileSync } from 'fs';

const sarifPath = process.argv[2] || 'socket-full.sarif';
const outPath = '.github/socket-baseline.json';

const sarif = JSON.parse(readFileSync(sarifPath, 'utf8'));
const run = sarif.runs?.[0];
const packages = new Set();

for (const result of run?.results || []) {
  const pkg = result.properties?.package || result.properties?.purl;
  if (pkg) packages.add(String(pkg));
}

const payload = {
  updatedAt: new Date().toISOString(),
  scanId: run?.automationDetails?.id || null,
  packages: [...packages].sort()
};

writeFileSync(outPath, `${JSON.stringify(payload, null, 2)}\n`);
console.log(`Updated baseline with ${payload.packages.length} package entries.`);
