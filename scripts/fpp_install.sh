#!/bin/bash
#
# FPP Install Script for Tailscale Plugin
# This script is called by FPP during plugin installation
#

PLUGIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "Installing Tailscale Plugin for FPP..."

# Install Tailscale if not already installed
if ! command -v tailscale &> /dev/null; then
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    if [ $? -eq 0 ]; then
        echo "Tailscale installed successfully"
    else
        echo "ERROR: Failed to install Tailscale"
        exit 1
    fi
else
    echo "Tailscale is already installed"
fi

# Create necessary directories
mkdir -p /var/lib/tailscale
mkdir -p /var/log

# Create log file if it doesn't exist
touch /var/log/fpp-tailscale.log
chmod 666 /var/log/fpp-tailscale.log

# Create default config if it doesn't exist
if [ ! -f "${PLUGIN_DIR}/config.json" ]; then
    cat > "${PLUGIN_DIR}/config.json" << EOF
{
    "auto_connect": false,
    "accept_routes": false,
    "advertise_exit": false,
    "hostname": "fpp-player"
}
EOF
    echo "Created default configuration"
fi

# Start tailscaled daemon if not running
if ! pgrep -x "tailscaled" > /dev/null; then
    echo "Starting tailscaled daemon..."
    tailscaled --state=/var/lib/tailscale/tailscaled.state > /dev/null 2>&1 &
    sleep 2
fi

echo "Tailscale Plugin installation complete!"
exit 0
