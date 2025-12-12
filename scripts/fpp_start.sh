#!/bin/bash
#
# FPP Start Script for Tailscale Plugin
# Ensures tailscaled is running when FPP starts
#

CONFIG_FILE="/home/fpp/media/config/plugin.testing-tailscale-fpp"
LOG_FILE="/var/log/fpp-tailscale.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "=== FPP Start - Tailscale Plugin ==="

# Read config value helper for INI files
get_config_value() {
    local key=$1
    if [ -f "$CONFIG_FILE" ]; then
        grep "^${key}\s*=" "$CONFIG_FILE" | cut -d'=' -f2- | tr -d ' '
    fi
}

# Ensure tailscaled is running
if ! pgrep -x "tailscaled" > /dev/null; then
    log "Tailscaled not running, starting it..."
    
    # Try systemctl first
    if sudo systemctl start tailscaled 2>/dev/null; then
        log "Started via systemctl"
        sleep 2
    else
        # Fallback to manual start
        sudo tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock > /dev/null 2>&1 &
        sleep 3
        log "Started manually"
    fi
fi

# Verify running
if pgrep -x "tailscaled" > /dev/null; then
    log "✓ Tailscaled is running"
else
    log "✗ Tailscaled failed to start"
    exit 1
fi

# Check auto-connect setting
auto_connect=$(get_config_value "auto_connect")
accept_routes=$(get_config_value "accept_routes")
hostname=$(get_config_value "hostname")

# Use system hostname if not set or default
if [ -z "$hostname" ] || [ "$hostname" = "fpp-player" ]; then
    hostname=$(hostname)
fi

if [ "$auto_connect" = "true" ] || [ "$auto_connect" = "True" ]; then
    log "Auto-connect enabled"
    
    # Wait for daemon to be ready
    sleep 2
    
    # Build tailscale up command with system hostname
    UP_CMD="sudo tailscale up --hostname=${hostname}"
    
    if [ "$accept_routes" = "true" ] || [ "$accept_routes" = "True" ]; then
        UP_CMD="$UP_CMD --accept-routes"
    fi
    
    # Execute connect
    if $UP_CMD >> "$LOG_FILE" 2>&1; then
        log "Auto-connect successful with hostname: ${hostname}"
    else
        log "Auto-connect completed (may need authentication)"
    fi
else
    log "Auto-connect disabled"
fi

log "=== Tailscale Plugin Start Complete ==="
exit 0
