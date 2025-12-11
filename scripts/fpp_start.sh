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

# Ensure tailscaled is running
log "Checking if tailscaled is running..."

if ! pgrep -x "tailscaled" > /dev/null; then
    log "Tailscaled not running, starting it..."
    
    # Check if systemd is available
    if pidof systemd > /dev/null 2>&1 && command -v systemctl &> /dev/null; then
        log "Using systemctl to start tailscaled..."
        systemctl start tailscaled 2>&1 >> "$LOG_FILE"
        sleep 2
    else
        log "Starting tailscaled manually..."
        nohup tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock > /dev/null 2>&1 &
        sleep 3
    fi
    
    if pgrep -x "tailscaled" > /dev/null; then
        log "Tailscaled daemon started successfully"
    else
        log "ERROR: Failed to start tailscaled daemon"
        exit 1
    fi
else
    log "Tailscaled daemon is already running (PID: $(pgrep -x tailscaled))"
fi

# Check if auto-connect is enabled
auto_connect=$(get_config_value "auto_connect")
accept_routes=$(get_config_value "accept_routes")
hostname=$(get_config_value "hostname")

if [ "$auto_connect" = "true" ] || [ "$auto_connect" = "True" ]; then
    log "Auto-connect enabled, attempting to connect..."
    
    # Wait a moment for daemon to be fully ready
    sleep 2
    
    # Check if already authenticated and connected
    if timeout 5 tailscale status 2>/dev/null | grep -q "Logged in"; then
        log "Already authenticated, bringing up connection..."
        
        # Build tailscale up command
        UP_CMD="tailscale up --hostname=${hostname:-fpp-player}"
        
        if [ "$accept_routes" = "true" ] || [ "$accept_routes" = "True" ]; then
            UP_CMD="$UP_CMD --accept-routes"
        fi
        
        $UP_CMD >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            log "Tailscale connection established"
        else
            log "WARNING: Tailscale up command had non-zero exit code (may still be connected)"
        fi
    else
        log "Not authenticated - manual authentication required via web UI"
    fi
else
    log "Auto-connect disabled"
fi

log "=== Tailscale Plugin Start Script Complete ==="
exit 0
