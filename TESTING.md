# Testing Guide for FPP Tailscale Plugin

This guide will help you test the Tailscale plugin in a Docker environment before deploying to production.

## Prerequisites

- Docker and Docker Compose installed
- Basic understanding of FPP
- A Tailscale account (free tier works fine)

## Quick Start

The fastest way to test:

```bash
cd fpp-tailscale-plugin
./quick-start.sh
```

This script will:
1. Check for Docker installation
2. Start the FPP container with the plugin
3. Open your browser to the FPP interface

## Manual Testing Steps

### 1. Start the Test Environment

```bash
docker-compose up -d
```

Wait ~30 seconds for FPP to fully initialize.

### 2. Access FPP

Open your browser to: http://localhost:8080

Default credentials (if prompted):
- Username: admin
- Password: (usually blank for fresh install)

### 3. Navigate to Plugin

1. Click on "Status/Control" in the main menu
2. Click on "Plugins"
3. Find "Tailscale" in the plugin list
4. Click to open the Tailscale management interface

### 4. Initial Connection Test

1. You should see "Disconnected from Tailscale" status
2. Click the "Connect" button
3. An authentication URL will appear
4. Click the URL to open Tailscale login page
5. Log in and authorize the device
6. Return to FPP - status should change to "Connected"

### 5. Configuration Test

Test each configuration option:

#### Auto-Connect on Boot
1. Enable "Auto-connect on boot" checkbox
2. Click "Save Configuration"
3. Restart container: `docker-compose restart`
4. After restart, verify plugin auto-connects

#### Custom Hostname
1. Enter a custom hostname (e.g., "fpp-test-1")
2. Click "Save Configuration"
3. Disconnect and reconnect
4. Verify hostname appears in Tailscale admin console

#### Accept Routes
1. Enable "Accept subnet routes"
2. Click "Save Configuration"
3. Reconnect to apply changes
4. Verify in Tailscale admin that routes are accepted

### 6. Remote Access Test

Once connected:

1. Note the Tailscale IP shown in the plugin (e.g., 100.64.x.x)
2. On another device with Tailscale installed:
   - Connect to your Tailscale network
   - Open browser to http://[tailscale-ip]
   - Verify FPP loads correctly

### 7. Connection Management Test

Test connection controls:

1. **Disconnect**: Click "Disconnect" - status should change
2. **Refresh**: Click "Refresh Status" - should update immediately
3. **Reconnect**: Click "Connect" - should reconnect without new auth

### 8. Logs Test

1. Navigate to the "Recent Logs" section
2. Verify logs are appearing
3. Click "Refresh Logs" to update
4. Perform actions (connect/disconnect) and verify they're logged

### 9. Docker Environment Tests

#### Test Plugin Installation
```bash
docker exec fpp-tailscale-test /opt/fpp/plugins/fpp-tailscale/plugin_setup install
```

Should complete without errors.

#### Test Plugin Startup
```bash
docker exec fpp-tailscale-test /opt/fpp/plugins/fpp-tailscale/plugin_setup start
```

Check logs:
```bash
docker exec fpp-tailscale-test tail -f /var/log/fpp-tailscale.log
```

#### Test Tailscale Commands
```bash
# Check Tailscale status
docker exec fpp-tailscale-test tailscale status

# Check if daemon is running
docker exec fpp-tailscale-test pgrep tailscaled

# View Tailscale configuration
docker exec fpp-tailscale-test cat /opt/fpp/plugins/fpp-tailscale/config.json
```

### 10. API Endpoint Tests

Test the PHP API directly:

```bash
# Get status
curl http://localhost:8080/plugins/fpp-tailscale/api.php?action=getStatus

# Get config
curl http://localhost:8080/plugins/fpp-tailscale/api.php?action=getConfig

# Save config (POST)
curl -X POST http://localhost:8080/plugins/fpp-tailscale/api.php?action=saveConfig \
  -H "Content-Type: application/json" \
  -d '{"auto_connect":true,"accept_routes":false,"hostname":"fpp-test"}'

# Get logs
curl http://localhost:8080/plugins/fpp-tailscale/api.php?action=getLogs
```

### 11. Error Handling Tests

#### Test Without Internet
```bash
# Disconnect network
docker network disconnect bridge fpp-tailscale-test

# Try to connect via UI - should show appropriate error

# Reconnect network
docker network connect bridge fpp-tailscale-test
```

#### Test With Invalid Config
1. Edit config manually:
```bash
docker exec fpp-tailscale-test sh -c 'echo "invalid json" > /opt/fpp/plugins/fpp-tailscale/config.json'
```
2. Try to load plugin - should handle gracefully
3. Reset config:
```bash
docker exec fpp-tailscale-test /opt/fpp/plugins/fpp-tailscale/plugin_setup install
```

#### Test Daemon Not Running
```bash
# Stop tailscaled
docker exec fpp-tailscale-test pkill tailscaled

# Check plugin status - should indicate daemon not running

# Restart daemon
docker exec fpp-tailscale-test tailscaled --state=/var/lib/tailscale/tailscaled.state &
```

### 12. Performance Tests

Monitor resource usage:

```bash
# CPU and memory usage
docker stats fpp-tailscale-test

# Should be minimal overhead (< 50MB RAM for Tailscale)
```

### 13. Persistence Tests

Test data persistence across restarts:

```bash
# Connect and configure plugin
# Stop container
docker-compose down

# Start container
docker-compose up -d

# Verify:
# - Configuration is preserved
# - Auto-connect works (if enabled)
# - Logs are maintained
```

### 14. Multiple Instance Tests (Advanced)

Test multiple FPP instances:

```yaml
# Create docker-compose.override.yml
version: '3.8'
services:
  fpp2:
    extends:
      service: fpp
    container_name: fpp-tailscale-test-2
    ports:
      - "8081:80"
```

```bash
docker-compose up -d
```

Verify:
- Both instances can connect to Tailscale
- Each gets unique Tailscale IP
- Both are accessible via their respective Tailscale IPs

## Common Issues & Solutions

### Plugin Not Appearing
- Verify plugin files are in `/opt/fpp/plugins/fpp-tailscale/`
- Check file permissions
- Restart FPP

### Can't Connect to Tailscale
- Check internet connectivity
- Verify /dev/net/tun exists
- Check if tailscaled is running: `pgrep tailscaled`
- Review logs: `/var/log/fpp-tailscale.log`

### Authentication Keeps Prompting
- Ensure you're completing the auth flow
- Check Tailscale account hasn't reached device limit
- Try logging out and back in: `tailscale logout`, then reconnect

### Container Won't Start
- Check if port 8080 is already in use
- Verify Docker has necessary permissions
- Check Docker logs: `docker logs fpp-tailscale-test`

## Cleanup

When done testing:

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker-compose down -v

# Remove images (optional)
docker rmi falconchristmas/fpp:latest
```

## Production Deployment

Once testing is complete:

1. Copy plugin to your production FPP:
```bash
scp -r fpp-tailscale-plugin/ fpp@your-fpp-ip:/opt/fpp/plugins/fpp-tailscale/
```

2. SSH to FPP and install:
```bash
ssh fpp@your-fpp-ip
cd /opt/fpp/plugins/fpp-tailscale
sudo ./plugin_setup install
```

3. Access plugin via FPP web interface and configure

## Continuous Testing

Set up automated checks:

```bash
#!/bin/bash
# test-suite.sh

echo "Running FPP Tailscale Plugin Tests..."

# Test 1: Plugin files exist
test -f /opt/fpp/plugins/fpp-tailscale/plugin_info.json && echo "✓ Plugin files present" || echo "✗ Plugin files missing"

# Test 2: Tailscale installed
command -v tailscale >/dev/null && echo "✓ Tailscale installed" || echo "✗ Tailscale missing"

# Test 3: Daemon running
pgrep tailscaled >/dev/null && echo "✓ Daemon running" || echo "✗ Daemon not running"

# Test 4: Config file exists
test -f /opt/fpp/plugins/fpp-tailscale/config.json && echo "✓ Config exists" || echo "✗ Config missing"

# Test 5: API responds
curl -s http://localhost/plugins/fpp-tailscale/api.php?action=getStatus | grep -q success && echo "✓ API working" || echo "✗ API not responding"

echo "Tests complete!"
```

## Need Help?

- Check logs: `/var/log/fpp-tailscale.log`
- FPP logs: `/var/log/fppd.log`
- Tailscale status: `tailscale status`
- Plugin status: Via web UI

Happy testing! 🎄
