#!/bin/bash
#
# FPP Install Script for Tailscale Plugin
# This script is called by FPP during plugin installation
#

PLUGIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
LOG_FILE="/var/log/fpp-tailscale.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "=== Starting Tailscale Plugin Installation ==="

# Create log file if it doesn't exist
touch "$LOG_FILE"
chmod 666 "$LOG_FILE"

# Check if Tailscale is already installed
if command -v tailscale &> /dev/null; then
    log "Tailscale is already installed"
    TAILSCALE_VERSION=$(tailscale version | head -n1)
    log "Current version: $TAILSCALE_VERSION"
else
    log "Installing Tailscale..."
    
    # Install Tailscale using official installation script
    if curl -fsSL https://tailscale.com/install.sh | sh; then
        log "Tailscale installed successfully"
        TAILSCALE_VERSION=$(tailscale version | head -n1)
        log "Installed version: $TAILSCALE_VERSION"
    else
        log "ERROR: Failed to install Tailscale"
        exit 1
    fi
fi

# Verify tailscale command is available
if ! command -v tailscale &> /dev/null; then
    log "ERROR: tailscale command not found after installation"
    exit 1
fi

# Verify tailscaled command is available
if ! command -v tailscaled &> /dev/null; then
    log "ERROR: tailscaled daemon not found after installation"
    exit 1
fi

# Create necessary directories
log "Creating necessary directories..."
mkdir -p /var/lib/tailscale
mkdir -p /var/run/tailscale
chmod 755 /var/lib/tailscale
chmod 755 /var/run/tailscale

# Create default config if it doesn't exist
if [ ! -f "${PLUGIN_DIR}/config.json" ]; then
    log "Creating default configuration..."
    cat > "${PLUGIN_DIR}/config.json" << 'EOF'
{
    "auto_connect": false,
    "accept_routes": false,
    "advertise_exit": false,
    "hostname": "fpp-player"
}
EOF
    log "Default configuration created"
fi

# Start tailscaled daemon
log "Starting tailscaled daemon..."

# Check if systemd is actually available and working
if pidof systemd > /dev/null 2>&1 && command -v systemctl &> /dev/null; then
    log "Using systemd to manage tailscaled..."
    
    # Enable the service to start on boot
    systemctl enable tailscaled 2>&1 | tee -a "$LOG_FILE"
    
    # Start the service now
    systemctl start tailscaled 2>&1 | tee -a "$LOG_FILE"
    
    # Wait a moment for service to start
    sleep 2
    
    # Check if service is running
    if systemctl is-active --quiet tailscaled; then
        log "Tailscaled service is running via systemd"
    else
        log "WARNING: Tailscaled service may not have started via systemd"
    fi
else
    log "Systemd not available, starting tailscaled manually..."
    
    # Kill any existing tailscaled processes
    pkill -x tailscaled 2>/dev/null || true
    sleep 1
    
    # Start tailscaled daemon manually in background
    nohup tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock > /dev/null 2>&1 &
    
    # Wait for daemon to start
    sleep 3
    
    if pgrep -x "tailscaled" > /dev/null; then
        log "Tailscaled daemon started successfully (manual mode)"
    else
        log "ERROR: Failed to start tailscaled daemon manually"
        exit 1
    fi
fi

# Final verification
log "Verifying installation..."
if pgrep -x "tailscaled" > /dev/null; then
    log "✓ Tailscaled daemon is running (PID: $(pgrep -x tailscaled))"
else
    log "✗ Tailscaled daemon is NOT running"
    exit 1
fi

# Test if tailscale CLI can communicate with daemon
log "Testing Tailscale CLI communication..."
if timeout 5 tailscale status &> /dev/null; then
    log "✓ Tailscale CLI is responsive"
else
    # This is expected if not yet authenticated
    log "⚠ Tailscale status check inconclusive (normal if not yet authenticated)"
fi

log "=== Tailscale Plugin Installation Complete ==="
log "Next steps:"
log "  1. Navigate to Status/Control → Tailscale VPN"
log "  2. Click 'Connect' to generate authentication URL"
log "  3. Complete authentication in your browser"

exit 0
