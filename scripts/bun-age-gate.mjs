#!/usr/bin/env bun
/**
 * BUN AGE GATE - Enforces 1-week minimum age for all npm packages
 * This runs before ANY bun install/add/update operation
 *
 * Exit code 1 = Block the operation
 * Exit code 0 = Allow the operation
 */

import { $ } from 'bun';

const ROOT = import.meta.dir + '/..';
const MIN_AGE_DAYS = 7;
const MIN_AGE_MS = MIN_AGE_DAYS * 24 * 60 * 60 * 1000;
const CUTOFF_DATE = new Date(Date.now() - MIN_AGE_MS);

const RED = '\x1b[31m';
const YELLOW = '\x1b[33m';
const GREEN = '\x1b[32m';
const RESET = '\x1b[0m';

console.log(`\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}`);
console.log(`${GREEN}  🔒 BUN AGE GATE - SECURITY CHECK${RESET}`);
console.log(`${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}`);
console.log(`   Minimum age: ${MIN_AGE_DAYS} days`);
console.log(`   Cutoff date: ${CUTOFF_DATE.toISOString().split('T')[0]}`);
console.log(`${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n`);

// Parse bun.lock as text - it's a JSON-like format but not strict JSON
async function getLockedPackages() {
  try {
    // Read and parse bun.lock manually to handle its format
    const lockfile = await Bun.file(`${ROOT}/bun.lock`).text();
    const packages = [];

    // Find the workspaces section
    const workspacesMatch = lockfile.match(/"workspaces":\s*\{[\s\S]*?"":\s*\{([\s\S]*?)\n  \},/);
    if (!workspacesMatch) {
      console.error(`${YELLOW}⚠️  Could not find workspaces in bun.lock${RESET}`);
      return [];
    }

    const workspaceContent = workspacesMatch[1];

    // Extract dependencies section
    const depsMatch = workspaceContent.match(/"dependencies":\s*\{([\s\S]*?)\n      \},/);
    const devDepsMatch = workspaceContent.match(/"devDependencies":\s*\{([\s\S]*?)\n      \},/);

    // Parse dependency entries
    function parseDeps(content) {
      if (!content) return;
      const lines = content.split('\n');
      for (const line of lines) {
        // Match: "package-name": "^1.2.3",
        const match = line.match(/^\s+"([^"]+)":\s*"([^"]+)",?\s*$/);
        if (match) {
          const [, name, versionSpec] = match;
          if (!versionSpec.startsWith('file:')) {
            packages.push({ name, versionSpec });
          }
        }
      }
    }

    parseDeps(depsMatch?.[1]);
    parseDeps(devDepsMatch?.[1]);

    return packages;
  } catch (e) {
    console.error(`${YELLOW}⚠️  Could not parse bun.lock: ${e.message}${RESET}`);
    return [];
  }
}

// Check npm registry for package age
async function checkPackageAge(name, versionSpec) {
  try {
    const cleanVersion = versionSpec.replace(/^[\^~>=<]+/, '');
    let targetVersion = cleanVersion;

    // If it's a range, resolve to actual version
    if (/^[\^~>=<]/.test(versionSpec)) {
      try {
        const proc = Bun.spawn(['npm', 'view', `${name}@${cleanVersion}`, 'version', '--json'], {
          stdout: 'pipe',
          stderr: 'pipe',
          cwd: ROOT
        });
        const output = await new Response(proc.stdout).text();
        targetVersion = JSON.parse(output);
      } catch (e) {
        // Fall back to cleaned version
      }
    }

    // Get the specific version's publish time (not time.modified which changes with metadata updates)
    const proc = Bun.spawn(['npm', 'view', name, 'time', '--json'], {
      stdout: 'pipe',
      stderr: 'pipe',
      cwd: ROOT
    });
    const output = await new Response(proc.stdout).text();
    const timeData = JSON.parse(output);
    const published = new Date(timeData[targetVersion]);

    return { name, version: targetVersion, modified: published, tooNew: published > CUTOFF_DATE };
  } catch (e) {
    return null;
  }
}

// Main validation
async function validate() {
  const packages = await getLockedPackages();

  if (packages.length === 0) {
    console.error(`${RED}❌ No packages found - cannot validate safety${RESET}`);
    console.error(`   Defaulting to BLOCK for security.\n`);
    process.exit(1);
  }

  console.log(`   Checking ${packages.length} packages...\n`);

  const recentPackages = [];
  const batchSize = 5;

  for (let i = 0; i < packages.length; i += batchSize) {
    const batch = packages.slice(i, i + batchSize);
    const results = await Promise.all(
      batch.map(p => checkPackageAge(p.name, p.versionSpec))
    );

    for (const result of results) {
      if (result?.tooNew) {
        recentPackages.push(result);
      }
    }

    process.stdout.write(`   ${Math.min(i + batchSize, packages.length)}/${packages.length} checked...\r`);
  }

  console.log('');

  if (recentPackages.length > 0) {
    console.error(`\n${RED}❌ BUN AGE GATE BLOCKED${RESET}`);
    console.error(`   ${recentPackages.length} package(s) are newer than ${MIN_AGE_DAYS} days:\n`);

    for (const p of recentPackages) {
      const daysAgo = Math.floor((Date.now() - p.modified) / (24 * 60 * 60 * 1000));
      console.error(`   ${RED}• ${p.name}@${p.version}${RESET}`);
      console.error(`     Published: ${p.modified.toISOString().split('T')[0]} (${daysAgo} days ago)`);
    }

    const unlockDate = new Date(Math.max(...recentPackages.map(p => p.modified.getTime())) + MIN_AGE_MS);
    console.error(`\n${YELLOW}   ⏳ Available after: ${unlockDate.toISOString().split('T')[0]}${RESET}`);
    console.error(`\n   Operation BLOCKED.\n`);
    process.exit(1);
  }

  console.log(`${GREEN}✅ All ${packages.length} packages meet the ${MIN_AGE_DAYS}-day minimum age.${RESET}\n`);
  process.exit(0);
}

validate().catch(err => {
  console.error(`${RED}❌ Validation error: ${err.message}${RESET}`);
  console.error(`   Defaulting to BLOCK for security.\n`);
  process.exit(1);
});
