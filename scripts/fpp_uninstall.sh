#!/bin/bash
#
# FPP Uninstall Script for Tailscale Plugin
# Cleans up Tailscale installation
#

LOG_FILE="/var/log/fpp-tailscale.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "=== Uninstalling Tailscale Plugin ==="

# Disconnect from Tailscale network
log "Disconnecting from Tailscale..."
sudo tailscale down 2>/dev/null || true

# Stop and disable service
log "Stopping tailscaled service..."
sudo systemctl stop tailscaled 2>/dev/null || true
sudo systemctl disable tailscaled 2>/dev/null || true

# Kill any running processes
sudo pkill -x tailscaled 2>/dev/null || true

# Optional: Remove Tailscale package (commented out by default)
# Uncomment if you want to completely remove Tailscale
# log "Removing Tailscale package..."
# sudo apt-get remove -y tailscale 2>/dev/null || true
# sudo apt-get purge -y tailscale 2>/dev/null || true

# Clean up plugin files
log "Cleaning up plugin files..."
rm -f /var/log/fpp-tailscale.log

log "=== Tailscale Plugin Uninstalled ==="
log "Note: Tailscale package was not removed. To remove it completely, run:"
log "  sudo apt-get remove -y tailscale"
log "  sudo apt-get purge -y tailscale"

exit 0
