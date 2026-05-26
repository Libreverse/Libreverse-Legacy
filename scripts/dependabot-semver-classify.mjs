#!/usr/bin/env bun
/**
 * Classify a Dependabot PR bump type from title/body and changed files.
 * Writes GITHUB_OUTPUT when GITHUB_OUTPUT is set.
 */

import { readFileSync, existsSync, appendFileSync } from 'fs';

const ROOT = `${import.meta.dir}/..`;

function writeOutput(key, value) {
  const outFile = process.env.GITHUB_OUTPUT;
  if (!outFile) {
    console.log(`${key}=${value}`);
    return;
  }
  appendFileSync(outFile, `${key}=${value}\n`);
}

function classifyFromTitle(title) {
  const t = title.toLowerCase();
  if (t.includes('github_actions') || t.includes('github actions')) return 'github-actions';
  if (/\bmajor\b/.test(t) || /from [\d.]+\s+to\s+[\d.]+/.test(t)) {
    const m = title.match(/from ([\d.]+) to ([\d.]+)/i);
    if (m) {
      const from = m[1].split('.').map(Number);
      const to = m[2].split('.').map(Number);
      if (to[0] > from[0]) return 'major';
      if (to[1] > from[1]) return 'minor';
      return 'patch';
    }
  }
  if (/\bminor\b/.test(t)) return 'minor';
  if (/\bpatch\b/.test(t)) return 'patch';
  return 'unknown';
}

function lockfileChurn() {
  try {
    const diff = Bun.spawnSync(['git', 'diff', '--stat', 'origin/main...HEAD', '--', 'bun.lock', 'Gemfile.lock'], {
      cwd: ROOT
    });
    const text = diff.stdout.toString();
    const lines = text.split('\n').filter(l => l.includes('|'));
    let total = 0;
    for (const line of lines) {
      const m = line.match(/\|\s*(\d+)\s*\+/);
      if (m) total += Number(m[1]);
    }
    return total;
  } catch {
    return 0;
  }
}

async function hasBreakingChangelog() {
  const title = process.env.PR_TITLE || '';
  if (!/major/i.test(title)) return false;
  // Heuristic: defer if PR body mentions BREAKING
  const bodyPath = process.env.PR_BODY_FILE;
  if (bodyPath && existsSync(bodyPath)) {
    const body = readFileSync(bodyPath, 'utf8');
    if (/\bBREAKING\b/i.test(body)) return true;
  }
  return false;
}

async function main() {
  const title = process.env.PR_TITLE || process.env.GITHUB_PR_TITLE || '';
  const bumpType = classifyFromTitle(title);
  const churn = lockfileChurn();
  const breaking = await hasBreakingChangelog();
  const majorMinAgeDays = Number(process.env.MAJOR_MIN_AGE_DAYS || '14');
  const lockChurnCap = Number(process.env.LOCK_CHURN_CAP || '5000');

  let automergeTier = 'none';
  if (bumpType === 'github-actions' || bumpType === 'patch') automergeTier = 'auto';
  else if (bumpType === 'minor') automergeTier = 'auto';
  else if (bumpType === 'major') automergeTier = breaking || churn > lockChurnCap ? 'deferred' : 'major-conditional';

  writeOutput('bump_type', bumpType);
  writeOutput('automerge_tier', automergeTier);
  writeOutput('lockfile_churn', String(churn));
  writeOutput('major_min_age_days', String(majorMinAgeDays));

  console.log(`Bump type: ${bumpType}, automerge tier: ${automergeTier}, lock churn: ${churn}`);
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
