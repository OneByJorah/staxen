#!/usr/bin/env bash
set -euo pipefail

# Load local port overrides from .env if present
if [ -f .env ]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

SERVER="${1:-localhost}"
PROFILE="${STACK_PROFILE:-core}"
printf "staxen Healthcheck\nTarget: %s (profile: %s)\n\n" "$SERVER" "$PROFILE"

check_service() {
    local name="$1"
    local url="$2"
    local expected="${3:-}"

    if [[ -n "$expected" ]]; then
        if curl -sf "$url" | grep -q "$expected"; then
            printf "  ✅ %s\n" "$name"
            return 0
        fi
    else
        if curl -sf "$url" >/dev/null; then
            printf "  ✅ %s\n" "$name"
            return 0
        fi
    fi
    printf "  ❌ %s\n" "$name"
    return 1
}

FAILED=0

echo "Core services:"
check_service "Landing page" "http://$SERVER:${SVC_STAXEN_PORT:-8085}/" "staxen" || FAILED=1
check_service "Obsidian Viewer" "http://$SERVER:${SVC_OBSIDIAN_PORT:-8083}/" "Vault" || FAILED=1
check_service "Qdrant" "http://$SERVER:${SVC_QDRANT_PORT:-6333}/readyz" "ready" || FAILED=1
check_service "Honcho API" "http://$SERVER:${SVC_HONCHO_PORT:-8000}/health" "" || FAILED=1
check_service "CouchDB" "http://$SERVER:${SVC_COUCHDB_PORT:-5984}/" "" || FAILED=1

if [[ "$PROFILE" == "full" ]]; then
    echo ""
    echo "Optional services (full profile):"
    check_service "SearXNG" "http://$SERVER:${SVC_SEARXNG_PORT:-8080}/search?q=healthcheck&format=json" "results" || FAILED=1
    check_service "Selenium Web Automation" "http://$SERVER:${SVC_SELENIUM_PORT:-4444}/status" "" || FAILED=1
    check_service "Syncthing UI" "http://$SERVER:${SVC_SYNCTHING_UI_PORT:-8384}/" "" || FAILED=1
    check_service "Ollama" "http://$SERVER:11434/" "" || FAILED=1
fi

echo ""
if [[ $FAILED -eq 0 ]]; then
    echo "🎉 All checked services are healthy!"
    exit 0
else
    echo "⚠️  Some services are down"
    exit 1
fi
