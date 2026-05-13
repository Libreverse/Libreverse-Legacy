#!/bin/bash
# Install Bundler Age Gate plugin globally
# Run this on any computer to enable the security check

set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/bundler-age_gate" && pwd)"
echo "Installing bundler-age_gate plugin..."

# Install the plugin globally using bundler's plugin system
(cd "$PLUGIN_DIR" && bundle plugin install --local .)

echo "✅ Age gate plugin installed!"
echo ""
echo "The age gate will now run automatically before every 'bundle install'"
echo "To uninstall: bundle plugin uninstall bundler-age_gate"
