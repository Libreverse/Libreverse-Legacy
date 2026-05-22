#!/usr/bin/env bun
/**
 * Pin package.json to specific versions that are at least 1 week old
 * This removes ^/~ prefixes to prevent automatic updates
 */

import { $ } from 'bun';

const ROOT = import.meta.dir + '/..';
const MIN_AGE_DAYS = 7;
const MIN_AGE_MS = MIN_AGE_DAYS * 24 * 60 * 60 * 1000;
const CUTOFF_DATE = new Date(Date.now() - MIN_AGE_MS);

const CYAN = '\u001B[36m';
const GREEN = '\u001B[32m';
const YELLOW = '\u001B[33m';
const RED = '\u001B[31m';
const RESET = '\u001B[0m';

console.log(`${CYAN}📌 PINNING TO SAFE VERSIONS${RESET}`);
console.log(`   Cutoff: ${CUTOFF_DATE.toISOString().split('T')[0]}\n`);

// Read current package.json
const packagePath = `${ROOT}/package.json`;
const package_ = JSON.parse(await Bun.file(packagePath).text());

async function findSafeVersion(name, currentSpec) {
  try {
    // Get all version timestamps
    const proc = Bun.spawn(['npm', 'view', name, 'time', '--json'], {
      stdout: 'pipe',
      stderr: 'pipe'
    });
    const output = await new Response(proc.stdout).text();
    const timeData = JSON.parse(output);

    // Find latest version published before cutoff
    let safeVersion = null;
    let safeDate = null;

    for (const [version, timestamp] of Object.entries(timeData)) {
      if (version === 'created' || version === 'modified') continue;
      const publishDate = new Date(timestamp);
      if (publishDate < CUTOFF_DATE && (!safeDate || publishDate > safeDate)) {
          safeDate = publishDate;
          safeVersion = version;
        }
    }

    return safeVersion ? { version: safeVersion, date: safeDate } : null;
  } catch {
    return null;
  }
}

async function processSection(sectionName) {
  const section = package_[sectionName];
  if (!section) return 0;

  let updated = 0;

  for (const [name, currentSpec] of Object.entries(section)) {
    // Skip file: and link: protocols
    if (currentSpec.startsWith('file:') || currentSpec.startsWith('link:')) continue;

    const cleanCurrent = currentSpec.replace(/^[\^~>=<]+/, '');
    const safe = await findSafeVersion(name, currentSpec);

    if (!safe) {
      console.log(`${YELLOW}⚠️${RESET} ${name}: No safe version found (keeping ${currentSpec})`);
      continue;
    }

    // Check if current resolved version would be too new
    const proc = Bun.spawn(['npm', 'view', `${name}@${cleanCurrent}`, 'time.modified', '--json'], {
      stdout: 'pipe',
      stderr: 'pipe'
    });
    const output = await new Response(proc.stdout).text();
    const currentDate = new Date(JSON.parse(output));

    if (currentDate >= CUTOFF_DATE) {
      // Need to pin to safe version
      section[name] = safe.version; // No ^ prefix - exact version
      const daysOld = Math.floor((CUTOFF_DATE - safe.date) / (24 * 60 * 60 * 1000));
      console.log(`${GREEN}✓${RESET} ${name}: ${currentSpec} → ${safe.version} (${daysOld} days before cutoff)`);
      updated++;
    } else {
      // Current is already safe, but pin it anyway to prevent future updates
      section[name] = cleanCurrent; // Remove ^/~ but keep same version
    }
  }

  return updated;
}

async function main() {
  const depUpdates = await processSection('dependencies');
  const developmentDepUpdates = await processSection('devDependencies');
  const total = depUpdates + developmentDepUpdates;

  if (total === 0) {
    console.log(`\n${GREEN}All versions are already safe.${RESET}\n`);
    return;
  }

  // Write updated package.json
  await Bun.write(packagePath, JSON.stringify(package_, null, 4) + '\n');

  console.log(`\n${CYAN}Pinned ${total} packages to exact safe versions${RESET}`);
  console.log(`\n${YELLOW}Next steps:${RESET}`);
  console.log(`   1. Review: git diff package.json`);
  console.log(`   2. Install: bun install --ignore-scripts`);
  console.log(`   3. Verify: bun scripts/bun-age-gate.mjs\n`);
}

main().catch(error => {
  console.error(`${RED}Error: ${error.message}${RESET}`);
  process.exit(1);
});
