#!/bin/bash
#
# FPP Start Script for Tailscale Plugin
# This script is called by FPP when it starts
#

PLUGIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
LOG_FILE="/var/log/fpp-tailscale.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "=== FPP Starting - Tailscale Plugin Start Script ==="

# Read configuration
get_config_value() {
    local key=$1
    if [ -f "${PLUGIN_DIR}/config.json" ]; then
        python3 -c "import json; print(json.load(open('${PLUGIN_DIR}/config.json')).get('$key', ''))" 2>/dev/null
    fi
}

# Start tailscaled daemon if not running
if ! pgrep -x "tailscaled" > /dev/null; then
    log "Starting tailscaled daemon..."
    tailscaled --state=/var/lib/tailscale/tailscaled.state > /dev/null 2>&1 &
    sleep 2
fi

# Check if auto-connect is enabled
auto_connect=$(get_config_value "auto_connect")
accept_routes=$(get_config_value "accept_routes")
hostname=$(get_config_value "hostname")

if [ "$auto_connect" = "true" ]; then
    log "Auto-connect enabled, attempting to connect..."
    
    # Check if already authenticated
    if tailscale status > /dev/null 2>&1; then
        log "Already authenticated, bringing up connection..."
        tailscale up --hostname="${hostname:-fpp-player}" --accept-routes=${accept_routes:-false} > /dev/null 2>&1
        log "Tailscale connection established"
    else
        log "Not authenticated - manual authentication required via web UI"
    fi
else
    log "Auto-connect disabled"
fi

log "=== Tailscale Plugin Start Script Complete ==="
exit 0
