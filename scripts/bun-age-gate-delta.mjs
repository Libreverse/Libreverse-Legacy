#!/usr/bin/env bun
/**
 * Delta age gate: only new (name, version) pairs in bun.lock vs base ref.
 * No install required. Exit 1 = block merge; exit 0 = allow.
 */

import { diffBunLockPackages } from './lib/bun-lock-packages.mjs';

const ROOT = `${import.meta.dir}/..`;
const MIN_AGE_DAYS = Number(process.env.MIN_AGE_DAYS || '7');
const MIN_AGE_MS = MIN_AGE_DAYS * 24 * 60 * 60 * 1000;
const CUTOFF_DATE = new Date(Date.now() - MIN_AGE_MS);
const BASE_REF = process.env.BASE_REF || 'origin/main';

const RED = '\u001B[31m';
const YELLOW = '\u001B[33m';
const GREEN = '\u001B[32m';
const RESET = '\u001B[0m';

async function readLockAtRef(ref) {
  const proc = Bun.spawn(['git', 'show', `${ref}:bun.lock`], {
    stdout: 'pipe',
    stderr: 'pipe',
    cwd: ROOT
  });
  const [code, text, err] = await Promise.all([
    proc.exited,
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text()
  ]);
  return { code, text, err };
}

async function readHeadLock() {
  return await Bun.file(`${ROOT}/bun.lock`).text();
}

async function checkPackageAge(name, version) {
  try {
    const proc = Bun.spawn(['npm', 'view', name, 'time', '--json'], {
      stdout: 'pipe',
      stderr: 'pipe',
      cwd: ROOT
    });
    const output = await new Response(proc.stdout).text();
    const timeData = JSON.parse(output);
    const published = new Date(timeData[version]);
    if (Number.isNaN(published.getTime())) return null;
    return { name, version, published, tooNew: published > CUTOFF_DATE };
  } catch {
    return null;
  }
}

async function main() {
  console.log(`\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}`);
  console.log(`${GREEN}  🔒 BUN DELTA AGE GATE${RESET}`);
  console.log(`${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}`);
  console.log(`   Base ref: ${BASE_REF}`);
  console.log(`   Minimum age: ${MIN_AGE_DAYS} days\n`);

  const headText = await readHeadLock();
  let baseText = '';
  const base = await readLockAtRef(BASE_REF);
  if (base.code === 0) {
    baseText = base.text;
  } else {
    console.log(`${YELLOW}⚠️  No base bun.lock at ${BASE_REF}; treating all packages as new${RESET}`);
    baseText = '{"packages":{}}\n';
  }

  const added = diffBunLockPackages(headText, baseText);
  if (added.length === 0) {
    console.log(`${GREEN}✅ No new npm packages in lockfile delta.${RESET}\n`);
    process.exit(0);
  }

  console.log(`   Checking ${added.length} new package version(s)...\n`);
  const tooYoung = [];
  const batchSize = 8;

  for (let i = 0; i < added.length; i += batchSize) {
    const batch = added.slice(i, i + batchSize);
    const results = await Promise.all(batch.map(p => checkPackageAge(p.name, p.version)));
    for (const r of results) {
      if (r?.tooNew) tooYoung.push(r);
    }
    process.stdout.write(`   ${Math.min(i + batchSize, added.length)}/${added.length} checked...\r`);
  }
  console.log('');

  if (tooYoung.length > 0) {
    console.error(`\n${RED}❌ BUN DELTA AGE GATE BLOCKED${RESET}`);
    for (const p of tooYoung) {
      const daysAgo = Math.floor((Date.now() - p.published) / (24 * 60 * 60 * 1000));
      console.error(`   ${RED}• ${p.name}@${p.version}${RESET} (${daysAgo}d old)`);
    }
    console.error(`\n${YELLOW}   PR can stay open; re-run gates when versions age in.${RESET}\n`);
    process.exit(1);
  }

  console.log(`${GREEN}✅ All ${added.length} new package version(s) meet ${MIN_AGE_DAYS}-day minimum age.${RESET}\n`);
  process.exit(0);
}

main().catch(err => {
  console.error(`${RED}❌ ${err.message}${RESET}`);
  process.exit(1);
});
