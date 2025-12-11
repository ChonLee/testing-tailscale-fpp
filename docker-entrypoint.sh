#!/bin/bash
set -e

echo "Starting FPP Tailscale Plugin Container..."

# Start Tailscale daemon in the background
echo "Starting Tailscale daemon..."
mkdir -p /var/lib/tailscale
tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &

# Wait a moment for tailscaled to start
sleep 2

# Run the plugin startup
if [ -x /opt/fpp/plugins/fpp-tailscale/plugin_setup ]; then
    echo "Running plugin startup..."
    /opt/fpp/plugins/fpp-tailscale/plugin_setup start || true
fi

# Start FPP (this should be the main FPP entrypoint)
# Check if there's an existing FPP entrypoint
if [ -f /usr/local/bin/fpp-entrypoint.sh ]; then
    exec /usr/local/bin/fpp-entrypoint.sh "$@"
elif [ -f /opt/fpp/scripts/fpp_start ]; then
    exec /opt/fpp/scripts/fpp_start "$@"
else
    # Fallback - start FPP daemon
    echo "Starting FPP daemon..."
    exec /usr/bin/fppd
fi
