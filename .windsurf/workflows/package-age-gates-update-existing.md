---
description: Update an existing package age gate setup with Dependabot and CI safeguards
---

# Update Existing Package Age Gates Workflow

Use this workflow when `/package-age-gates` has already been applied to a repository and you only need to add the later safeguards for rolling dependency automation.

This workflow assumes the repo already has:

- `scripts/bun-age-gate.mjs`
- `scripts/gem-age-gate.rb`
- `package.json` `preinstall` hook for Bun
- Optional Bundler plugin under `plugins/bundler-age_gate`

## 1. Harden Dependabot so it does not propose too-fresh versions

Open `.github/dependabot.yml`.

For every configured ecosystem, add an 8-day cooldown with explicit semver fields:

```yaml
cooldown:
    default-days: 8
    semver-major-days: 8
    semver-minor-days: 8
    semver-patch-days: 8
```

Example complete config:

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

Use 8 days rather than 7 days to avoid edge cases around timezones, publish timestamp precision, and weekly scheduling.

Important: GitHub documents that Dependabot cooldown applies to version updates, not security updates.

## 2. Add an early CI backstop

Open the main CI workflow, usually `.github/workflows/ci.yml`.

Ensure it runs on pull requests:

```yaml
on:
    pull_request:
    push:
        branches:
            - "main"
```

Add this job before jobs that install dependencies:

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

Do not use a shared setup action here if that action runs `bundle install`, `bun install`, `npm install`, or any other dependency installation first.

This job is a backstop. Dependabot cooldowns should prevent normal rolling update PRs from failing this job.

## 3. Harden Dependabot auto-merge

Open the workflow that auto-approves or auto-merges Dependabot PRs, often `.github/workflows/auto-approve.yml`.

Keep auto-merge enabled, but make it wait for checks first.

Before every `gh pr merge`, add:

```bash
gh pr checks <PR_NUMBER> --repo <OWNER/REPO> --watch --fail-fast
```

For a `pull_request_target` Dependabot workflow, use:

```yaml
- name: Auto-merge Dependabot PR
  if: github.event_name == 'pull_request_target' && github.actor == 'dependabot[bot]'
  env:
      GH_TOKEN: ${{ steps.app-token.outputs.token }}
  run: |
      gh pr checks ${{ github.event.pull_request.number }} --repo ${{ github.repository }} --watch --fail-fast
      gh pr merge ${{ github.event.pull_request.number }} --repo ${{ github.repository }} --rebase --delete-branch --auto || echo "Failed to auto-merge (may need retry)"
```

For bulk/manual Dependabot merge loops, add the same check inside the loop:

```yaml
run: |
    prs=$(gh pr list --author dependabot[bot] --state open --json number --jq '.[].number')
    for pr in $prs; do
      gh pr review $pr --approve
      gh pr checks $pr --repo ${{ github.repository }} --watch --fail-fast
      gh pr merge $pr --rebase --delete-branch --auto || echo "Failed to merge PR #$pr"
    done
```

## 4. Verify the setup

Check these files:

```bash
cat .github/dependabot.yml
cat .github/workflows/ci.yml
cat .github/workflows/auto-approve.yml
```

Expected properties:

- Dependabot has 8-day cooldowns for every relevant ecosystem.
- CI has a `package-age-gates` job that runs before dependency installation.
- CI runs on pull requests.
- Auto-merge waits for PR checks before merge.

## 5. Policy notes

- Keep auto-merge if unattended patching is required.
- Dependabot cooldown should be the primary control for normal rolling version updates.
- CI age gates should be a backstop, not the normal mechanism for blocking Dependabot PRs.
- Dependabot security updates may bypass cooldowns according to GitHub documentation.
