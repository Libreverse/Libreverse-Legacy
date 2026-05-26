/**
 * Parse resolved name@version pairs from bun.lock "packages" section.
 */

export function parseBunLockPackages(lockText) {
  const packages = new Map();
  const packagesStart = lockText.indexOf('"packages":');
  if (packagesStart === -1) return packages;

  const slice = lockText.slice(packagesStart);
  const re = /^\s+"([^"]+)":\s*\["([^"]+)@([^"]+)"/gm;
  let match;
  while ((match = re.exec(slice)) !== null) {
    const [, , name, version] = match;
    packages.set(`${name}@${version}`, { name, version });
  }
  return packages;
}

export function diffBunLockPackages(headText, baseText) {
  const head = parseBunLockPackages(headText);
  const base = parseBunLockPackages(baseText);
  const added = [];
  for (const [key, pkg] of head) {
    if (!base.has(key)) added.push(pkg);
  }
  return added;
}
