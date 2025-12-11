#!/bin/bash
#
# Demo Script - Shows typical usage of FPP Tailscale Plugin
# This script demonstrates common operations you can perform
#

set -e

echo "=========================================="
echo "FPP Tailscale Plugin - Demo Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

demo_step() {
    echo -e "${GREEN}[DEMO]${NC} $1"
    echo ""
}

demo_command() {
    echo -e "${YELLOW}$ $1${NC}"
    eval $1
    echo ""
}

demo_step "1. Checking if Tailscale is installed"
demo_command "command -v tailscale && echo 'Tailscale is installed' || echo 'Tailscale not found'"

demo_step "2. Checking Tailscale daemon status"
demo_command "pgrep tailscaled > /dev/null && echo 'Daemon is running' || echo 'Daemon is not running'"

demo_step "3. Viewing current Tailscale status"
demo_command "tailscale status || echo 'Not connected'"

demo_step "4. Checking plugin configuration"
demo_command "cat /opt/fpp/plugins/fpp-tailscale/config.json 2>/dev/null || echo 'Config not found - plugin may not be installed'"

demo_step "5. Viewing recent plugin logs"
demo_command "tail -20 /var/log/fpp-tailscale.log 2>/dev/null || echo 'No logs found yet'"

echo ""
echo "=========================================="
echo "Common Operations"
echo "=========================================="
echo ""

cat << 'EOF'
# Connect to Tailscale
tailscale up --hostname=fpp-player

# Disconnect from Tailscale
tailscale down

# Check connection status
tailscale status

# View IP address
tailscale ip -4

# View network peers
tailscale status | grep -v '^#'

# Enable auto-connect (via config)
cat > /opt/fpp/plugins/fpp-tailscale/config.json << CONFIG
{
    "auto_connect": true,
    "accept_routes": false,
    "hostname": "fpp-player"
}
CONFIG

# Test API endpoints
curl http://localhost/plugins/fpp-tailscale/api.php?action=getStatus
curl http://localhost/plugins/fpp-tailscale/api.php?action=getConfig

# View Tailscale logs
journalctl -u tailscaled -n 50

# Restart Tailscale daemon
sudo systemctl restart tailscaled
EOF

echo ""
echo "=========================================="
echo "Demo complete!"
echo "=========================================="
echo ""
echo "Try these commands yourself or use the web UI at:"
echo "http://localhost/plugins/fpp-tailscale/"
echo ""
