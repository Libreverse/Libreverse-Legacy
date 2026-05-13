# Bundler Age Gate Plugin

Enforces a 1-week minimum age for all gems installed via Bundler.

## Install

From the project root:

```bash
bundle plugin install bundler-age_gate --path plugins/bundler-age_gate
```

## How it works

Once installed, the plugin hooks into Bundler's `before-install-all` event and:

1. Runs `scripts/gem-age-gate.rb`
2. Parses `Gemfile.lock` to find resolved gems
3. Checks RubyGems API for each gem version's publish date
4. Blocks install if any gem is newer than 7 days

## Uninstall

```bash
bundle plugin uninstall bundler-age_gate
```
