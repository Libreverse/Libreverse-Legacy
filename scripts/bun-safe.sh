#!/bin/bash
# bun-safe.sh - Wrapper that enforces 1-week age gate on all bun package operations
# Usage: source scripts/bun-safe.sh  # Then use 'bun-safe' instead of 'bun'
# Or: alias bun='scripts/bun-safe.sh'

bun-safe() {
    local cmd="$1"
    shift

    # List of package-modifying commands
    case "$cmd" in
        install|i|add|update|upgrade)
            echo "🔒 BUN AGE GATE: Validating packages before '$cmd'..."
            if ! node "$(dirname "$0")/bun-age-gate.mjs"; then
                echo ""
                echo "❌ Operation '$cmd' blocked by age gate"
                return 1
            fi
            ;;
    esac

    # Run the actual bun command
    command bun "$cmd" "$@"
}

# If this script is executed directly, run the age check
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    node "$(dirname "$0")/bun-age-gate.mjs"
fi
