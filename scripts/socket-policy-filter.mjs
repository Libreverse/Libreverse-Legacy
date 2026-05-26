#!/usr/bin/env bun
/**
 * Apply autonomous-rolling Socket policy to SARIF diff results.
 * Obfuscation alone does not block; obfuscation + install-script does.
 */

import { readFileSync, existsSync } from 'fs';

const sarifPath = process.argv[2] || 'socket-results.sarif';
const baselinePath = process.env.SOCKET_BASELINE_PATH || '.github/socket-baseline.json';

const RED = '\u001B[31m';
const YELLOW = '\u001B[33m';
const GREEN = '\u001B[32m';
const RESET = '\u001B[0m';

function loadJson(path, fallback) {
  if (!existsSync(path)) return fallback;
  return JSON.parse(readFileSync(path, 'utf8'));
}

function ruleText(result, rulesById) {
  const rule = rulesById.get(result.ruleId) || {};
  const parts = [
    result.ruleId,
    rule.name,
    rule.shortDescription?.text,
    rule.fullDescription?.text,
    result.message?.text
  ].filter(Boolean);
  return parts.join(' ').toLowerCase();
}

function classify(result, rulesById) {
  const text = ruleText(result, rulesById);
  const props = result.properties || {};
  const pkg = props.package || props.purl || props.artifact || '';

  const obfuscated =
    /obfuscat|minified|packed/.test(text) || props.category === 'obfuscated';
  const installScript =
    /install[\s_-]?script|lifecycle|postinstall|preinstall|install script/.test(text) ||
    props.category === 'installScript';
  const malware =
    /malware|protestware|backdoor|trojan/.test(text) || props.severity === 'critical';
  const typosquat =
    /typosquat|namespace confusion/.test(text) && /high|critical/.test(text);
  const takeover = /install-script takeover|script takeover/.test(text);
  const cve = /cve|vulnerabilit/.test(text) && /reachable|exploit/.test(text);

  if (malware || typosquat || takeover) return { action: 'block', reason: 'critical', pkg };
  if (cve) return { action: 'block', reason: 'cve', pkg };
  if (obfuscated && installScript) return { action: 'block', reason: 'obfuscation+install', pkg };
  if (obfuscated) return { action: 'ignore', reason: 'obfuscation-alone', pkg };
  if (/license|maintenance|reputation|quality/.test(text)) return { action: 'ignore', reason: 'info', pkg };

  // Default: respect Socket blocking level when present
  const level = (props.action || props.level || '').toLowerCase();
  if (level === 'error' || level === 'block') return { action: 'block', reason: 'socket-block', pkg };
  if (level === 'warn') return { action: 'warn', reason: 'socket-warn', pkg };
  return { action: 'warn', reason: 'unknown', pkg };
}

function main() {
  if (!existsSync(sarifPath)) {
    console.error(`${RED}❌ SARIF file not found: ${sarifPath}${RESET}`);
    process.exit(1);
  }

  const sarif = JSON.parse(readFileSync(sarifPath, 'utf8'));
  const run = sarif.runs?.[0];
  if (!run) {
    console.log(`${GREEN}✅ No SARIF run data; nothing to block.${RESET}`);
    process.exit(0);
  }

  const rulesById = new Map();
  for (const rule of run.tool?.driver?.rules || []) {
    rulesById.set(rule.id, rule);
  }

  const baseline = loadJson(baselinePath, { packages: [] });
  const baselineSet = new Set(baseline.packages || []);

  const results = run.results || [];
  const blocking = [];
  const ignored = [];
  const warned = [];

  for (const result of results) {
    const decision = classify(result, rulesById);
    const pkgKey = String(decision.pkg || result.ruleId);
    if (baselineSet.has(pkgKey)) {
      ignored.push({ ...decision, pkg: pkgKey, note: 'baseline-safe' });
      continue;
    }
    if (decision.action === 'block') blocking.push(decision);
    else if (decision.action === 'ignore') ignored.push(decision);
    else warned.push(decision);
  }

  console.log(`\n${GREEN}Socket policy filter${RESET}`);
  console.log(`   Results: ${results.length}, block: ${blocking.length}, warn: ${warned.length}, ignore: ${ignored.length}\n`);

  if (blocking.length > 0) {
    console.error(`${RED}❌ SOCKET DELTA POLICY BLOCKED${RESET}`);
    for (const b of blocking) {
      console.error(`   ${RED}• [${b.reason}] ${b.pkg || '(unknown)'}${RESET}`);
    }
    process.exit(1);
  }

  if (warned.length > 0) {
    console.log(`${YELLOW}⚠️  ${warned.length} warning(s) logged (non-blocking).${RESET}`);
  }

  console.log(`${GREEN}✅ Socket delta policy passed.${RESET}\n`);
  process.exit(0);
}

main();
