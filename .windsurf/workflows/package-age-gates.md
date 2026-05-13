---
description: Recreate npm/Bun and RubyGems/Bundler package age gates
---

# Package Age Gates Workflow

Use this workflow to add a 7-day package age gate to another repository.

The goal is to block package installs when any resolved package version is newer than 7 days old.

## 1. Bun / npm age gate

Create `scripts/bun-age-gate.mjs`:

```javascript
#!/usr/bin/env bun

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

async function getLockedPackages() {
  try {
    const lockfile = await Bun.file(`${ROOT}/bun.lock`).text();
    const packages = [];
    const workspacesMatch = lockfile.match(/"workspaces":\s*\{[\s\S]*?"":\s*\{([\s\S]*?)\n  \},/);
    if (!workspacesMatch) {
      console.error(`${YELLOW}⚠️  Could not find workspaces in bun.lock${RESET}`);
      return [];
    }

    const workspaceContent = workspacesMatch[1];
    const depsMatch = workspaceContent.match(/"dependencies":\s*\{([\s\S]*?)\n      \},/);
    const devDepsMatch = workspaceContent.match(/"devDependencies":\s*\{([\s\S]*?)\n      \},/);

    function parseDeps(content) {
      if (!content) return;
      for (const line of content.split('\n')) {
        const match = line.match(/^\s+"([^"]+)":\s*"([^"]+)",?\s*$/);
        if (match) {
          const [, name, versionSpec] = match;
          if (!versionSpec.startsWith('file:')) packages.push({ name, versionSpec });
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

async function checkPackageAge(name, versionSpec) {
  try {
    const cleanVersion = versionSpec.replace(/^[\^~>=<]+/, '');
    let targetVersion = cleanVersion;

    if (/^[\^~>=<]/.test(versionSpec)) {
      try {
        const proc = Bun.spawn(['npm', 'view', `${name}@${cleanVersion}`, 'version', '--json'], {
          stdout: 'pipe',
          stderr: 'pipe',
          cwd: ROOT
        });
        const output = await new Response(proc.stdout).text();
        targetVersion = JSON.parse(output);
      } catch {}
    }

    const proc = Bun.spawn(['npm', 'view', name, 'time', '--json'], {
      stdout: 'pipe',
      stderr: 'pipe',
      cwd: ROOT
    });
    const output = await new Response(proc.stdout).text();
    const timeData = JSON.parse(output);
    const published = new Date(timeData[targetVersion]);

    return { name, version: targetVersion, published, tooNew: published > CUTOFF_DATE };
  } catch {
    return null;
  }
}

async function validate() {
  const packages = await getLockedPackages();
  if (packages.length === 0) {
    console.error(`${RED}❌ No packages found - cannot validate safety${RESET}`);
    console.error('   Defaulting to BLOCK for security.\n');
    process.exit(1);
  }

  console.log(`   Checking ${packages.length} packages...\n`);
  const recentPackages = [];
  const batchSize = 5;

  for (let i = 0; i < packages.length; i += batchSize) {
    const batch = packages.slice(i, i + batchSize);
    const results = await Promise.all(batch.map(p => checkPackageAge(p.name, p.versionSpec)));
    for (const result of results) if (result?.tooNew) recentPackages.push(result);
    process.stdout.write(`   ${Math.min(i + batchSize, packages.length)}/${packages.length} checked...\r`);
  }

  console.log('');

  if (recentPackages.length > 0) {
    console.error(`\n${RED}❌ BUN AGE GATE BLOCKED${RESET}`);
    console.error(`   ${recentPackages.length} package(s) are newer than ${MIN_AGE_DAYS} days:\n`);
    for (const p of recentPackages) {
      const daysAgo = Math.floor((Date.now() - p.published) / (24 * 60 * 60 * 1000));
      console.error(`   ${RED}• ${p.name}@${p.version}${RESET}`);
      console.error(`     Published: ${p.published.toISOString().split('T')[0]} (${daysAgo} days ago)`);
    }
    const unlockDate = new Date(Math.max(...recentPackages.map(p => p.published.getTime())) + MIN_AGE_MS);
    console.error(`\n${YELLOW}   ⏳ Available after: ${unlockDate.toISOString().split('T')[0]}${RESET}`);
    console.error('\n   Operation BLOCKED.\n');
    process.exit(1);
  }

  console.log(`${GREEN}✅ All ${packages.length} packages meet the ${MIN_AGE_DAYS}-day minimum age.${RESET}\n`);
}

validate().catch(err => {
  console.error(`${RED}❌ Validation error: ${err.message}${RESET}`);
  console.error('   Defaulting to BLOCK for security.\n');
  process.exit(1);
});
```

Add this to `package.json`:

```json
{
  "scripts": {
    "preinstall": "bun scripts/bun-age-gate.mjs || exit 1"
  }
}
```

This makes normal `bun install`, `bun add`, and `bun update` visibly run the gate before proceeding.

## 2. RubyGems age gate script

Create `scripts/gem-age-gate.rb`:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler'
require 'net/http'
require 'json'
require 'date'

MIN_AGE_DAYS = 7
MIN_AGE_SECONDS = MIN_AGE_DAYS * 24 * 60 * 60
CUTOFF_DATE = Time.now - MIN_AGE_SECONDS

RED = "\e[31m"
YELLOW = "\e[33m"
GREEN = "\e[32m"
RESET = "\e[0m"

puts "\n#{GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{RESET}"
puts "#{GREEN}  🔒 GEM AGE GATE - SECURITY CHECK#{RESET}"
puts "#{GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{RESET}"
puts "   Minimum age: #{MIN_AGE_DAYS} days"
puts "   Cutoff date: #{CUTOFF_DATE.strftime('%Y-%m-%d')}"
puts "#{GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{RESET}\n"

def parse_gemfile_lock
  content = File.read(File.join(__dir__, '..', 'Gemfile.lock'))
  gems = {}
  in_specs = false

  content.each_line do |line|
    if line =~ /^GEM$/
      in_specs = false
    elsif line =~ /^  specs:$/
      in_specs = true
    elsif in_specs && line =~ /^    ([\w\-_.]+) \(([^)]+)\)$/
      gems[$1] = $2.split(',').first.strip
    elsif line =~ /^PLATFORMS/ || line =~ /^DEPENDENCIES/
      in_specs = false
    end
  end

  gems
end

def get_publish_date(name, version)
  uri = URI("https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 5
  http.read_timeout = 5

  response = http.request(Net::HTTP::Get.new(uri))
  return nil unless response.code == '200'

  DateTime.parse(JSON.parse(response.body)['created_at']).to_time
rescue
  nil
end

def validate
  gems = parse_gemfile_lock
  if gems.empty?
    puts "#{RED}❌ No gems found - cannot validate safety#{RESET}"
    puts "   Defaulting to BLOCK for security.\n"
    exit 1
  end

  puts "   Checking #{gems.length} gems in parallel...\n"
  recent_gems = []
  checked = 0
  mutex = Mutex.new

  gems.each_slice(20) do |batch|
    threads = batch.map do |name, version|
      Thread.new do
        published = get_publish_date(name, version)
        mutex.synchronize do
          checked += 1
          if published && published > CUTOFF_DATE
            recent_gems << { name: name, version: version, published: published }
          end
          print "   #{checked}/#{gems.length} checked...\r"
          $stdout.flush
        end
      end
    end
    threads.each(&:join)
    sleep 0.5
  end

  puts "\n"

  if recent_gems.any?
    puts "\n#{RED}❌ GEM AGE GATE BLOCKED#{RESET}"
    puts "   #{recent_gems.length} gem(s) are newer than #{MIN_AGE_DAYS} days:\n"
    recent_gems.each do |g|
      days_ago = ((Time.now - g[:published]) / (24 * 60 * 60)).to_i
      puts "   #{RED}• #{g[:name]} (#{g[:version]})#{RESET}"
      puts "     Published: #{g[:published].strftime('%Y-%m-%d')} (#{days_ago} days ago)"
    end
    unlock_date = recent_gems.map { |g| g[:published] }.max + MIN_AGE_SECONDS
    puts "\n#{YELLOW}   ⏳ Available after: #{unlock_date.strftime('%Y-%m-%d')}#{RESET}"
    puts "\n   Operation BLOCKED.\n"
    exit 1
  end

  puts "#{GREEN}✅ All #{gems.length} gems meet the #{MIN_AGE_DAYS}-day minimum age.#{RESET}\n"
end

validate
```

## 3. Bundler plugin

Create this structure:

```text
plugins/bundler-age_gate/
  bundler-age_gate.gemspec
  plugins.rb
  lib/bundler-age_gate.rb
```

Create `plugins/bundler-age_gate/bundler-age_gate.gemspec`:

```ruby
# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'bundler-age_gate'
  s.version = '1.0.0'
  s.summary = 'Enforces minimum gem age for security'
  s.description = 'Bundler plugin that blocks install if gems are newer than 7 days'
  s.authors = ['Security']
  s.files = ['plugins.rb', 'lib/bundler-age_gate.rb']
  s.require_paths = ['lib']
end
```

Create `plugins/bundler-age_gate/plugins.rb`:

```ruby
# frozen_string_literal: true

require_relative 'lib/bundler-age_gate'
```

Create `plugins/bundler-age_gate/lib/bundler-age_gate.rb`:

```ruby
# frozen_string_literal: true

require 'bundler/plugin/api'

Bundler::Plugin::API.hook('before-install-all') do |_dependencies|
  next if ENV['BUNDLER_AGE_GATE_RAN'] == '1'

  ENV['BUNDLER_AGE_GATE_RAN'] = '1'
  unless system('ruby', 'scripts/gem-age-gate.rb')
    abort 'Gem age gate failed - bundle install blocked'
  end
end
```

Install it in each environment:

```bash
bundle plugin install bundler-age_gate --path plugins/bundler-age_gate
```

Important: Bundler plugins are per-user/per-environment. The repo can carry the plugin source, but each developer/CI environment must install it once with the command above.

## 4. Optional Gemfile pointer

Add near the top of `Gemfile`:

```ruby
# Security: Enforce 1-week minimum age for all gems
# Install with: bundle plugin install bundler-age_gate --path plugins/bundler-age_gate
plugin 'bundler-age_gate', path: 'plugins/bundler-age_gate'
```

This documents the intended plugin and helps Bundler-aware tooling identify it.

## 5. Dependabot cooldowns

If the repository uses Dependabot for rolling dependency updates, configure Dependabot so it does not propose versions that the age gates will reject.

Create or update `.github/dependabot.yml`:

```yaml
version: 2
updates:
    - package-ecosystem: "bundler"
      directory: "/"
      schedule:
          interval: "weekly"
      cooldown:
          default-days: 8
          semver-major-days: 8
          semver-minor-days: 8
          semver-patch-days: 8
    - package-ecosystem: "npm"
      directory: "/"
      schedule:
          interval: "weekly"
      cooldown:
          default-days: 8
          semver-major-days: 8
          semver-minor-days: 8
          semver-patch-days: 8
    - package-ecosystem: "docker"
      directory: "/"
      schedule:
          interval: "weekly"
      cooldown:
          default-days: 8
          semver-major-days: 8
          semver-minor-days: 8
          semver-patch-days: 8
    - package-ecosystem: "github-actions"
      directory: "/"
      schedule:
          interval: "weekly"
      cooldown:
          default-days: 8
          semver-major-days: 8
          semver-minor-days: 8
          semver-patch-days: 8
```

Use 8 days rather than 7 days to avoid edge cases around timezones, release timestamp precision, and weekly scheduling.

Important: Dependabot cooldowns apply to version updates. GitHub documentation says cooldown does not apply to Dependabot security updates. If security updates are enabled in repository settings, they may still open PRs for versions younger than the gate allows.

## 6. CI package age gates

Add an early CI job that checks package ages before any dependency installation. This job is a backstop, not the primary control for Dependabot. Dependabot should avoid failing PRs via cooldown, and CI should catch unexpected misses.

In `.github/workflows/ci.yml`, ensure CI runs on pull requests:

```yaml
on:
    pull_request:
    push:
        branches:
            - "main"
```

Add this job before dependency-installing jobs:

```yaml
jobs:
    package-age-gates:
        name: Package age gates
        runs-on: ubuntu-22.04
        permissions:
            contents: read
        steps:
            - name: Check out code
              uses: actions/checkout@v6

            - name: Setup Ruby
              uses: ruby/setup-ruby@v1
              with:
                  bundler-cache: false

            - name: Setup Bun
              uses: oven-sh/setup-bun@v2
              with:
                  bun-version-file: .bun-version

            - name: Check npm/Bun package ages
              shell: bash
              run: bun scripts/bun-age-gate.mjs

            - name: Check RubyGems package ages
              shell: bash
              run: ruby scripts/gem-age-gate.rb
```

Do not call a shared setup action that runs `bundle install` or `bun install` before this job runs.

## 7. Auto-merge hardening

If Dependabot PRs are auto-approved and auto-merged, keep auto-merge but require checks to complete first.

In the auto-merge workflow, before `gh pr merge`, add:

```bash
gh pr checks "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" --watch --fail-fast
```

For a pull request target workflow, this commonly looks like:

```yaml
- name: Auto-merge Dependabot PR
  if: github.event_name == 'pull_request_target' && github.actor == 'dependabot[bot]'
  env:
      GH_TOKEN: ${{ steps.app-token.outputs.token }}
  run: |
      gh pr checks ${{ github.event.pull_request.number }} --repo ${{ github.repository }} --watch --fail-fast
      gh pr merge ${{ github.event.pull_request.number }} --repo ${{ github.repository }} --rebase --delete-branch --auto || echo "Failed to auto-merge (may need retry)"
```

This preserves rolling automation while preventing auto-merge from racing ahead of the package age check.

## 8. Verification

Run:

```bash
bun install
bundle install
```

Expected Bun output includes:

```text
🔒 BUN AGE GATE - SECURITY CHECK
✅ All packages meet the 7-day minimum age.
```

Expected Bundler output includes:

```text
🔒 GEM AGE GATE - SECURITY CHECK
✅ All gems meet the 7-day minimum age.
```

## 9. Known limitations

- Bun enforcement is automatic through `package.json` lifecycle scripts.
- Bundler enforcement requires the Bundler plugin to be installed once per environment.
- Dependabot cooldown prevents normal rolling version updates from proposing too-fresh versions, but does not apply to security updates.
- CI age gates are a backstop and should not be the normal mechanism for blocking Dependabot version PRs, because failing PRs break unattended rolling automation.
- Do not use git hooks as the primary control; they run too late and are easy to bypass.
- Do not use wrapper aliases as the primary control; developers can forget them.
- The RubyGems check validates versions already resolved in `Gemfile.lock`.
