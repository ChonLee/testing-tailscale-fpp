CURRENT STATUS ***BROKEN***

# FPP Tailscale Plugin

A Falcon Player (FPP) plugin that integrates Tailscale VPN for secure remote access to your FPP instance.

## Features

- 🔐 Secure remote access to FPP through Tailscale VPN
- 🚀 Auto-connect on boot (optional)
- 🖥️ Web-based management interface
- 📊 Real-time connection status
- 🔧 Easy configuration management
- 📝 Built-in logging
- 🐳 Docker-friendly for testing

## Requirements

- FPP 7.0 or later
- Raspberry Pi or compatible hardware
- Internet connection
- Tailscale account (free tier available at https://tailscale.com)

## Installation

### Method 1: Via FPP Plugin Manager (Recommended)

1. Open FPP web interface
2. Navigate to Content Setup → Plugin Manager
3. Click "Install Plugin from Repository"
4. Search for "fpp-tailscale"
5. Click Install

### Method 2: Manual Installation

1. SSH into your FPP device
2. Navigate to the plugins directory:
   ```bash
   cd /opt/fpp/plugins
   ```
3. Clone or copy the plugin:
   ```bash
   git clone https://github.com/yourusername/fpp-tailscale.git fpp-tailscale
   ```
4. Run the installation:
   ```bash
   cd fpp-tailscale
   sudo ./plugin_setup install
   ```

### Method 3: Docker Testing Environment

For testing the plugin in a Docker container:

```bash
# Create a docker-compose.yml file (see Docker section below)
docker-compose up -d

# Access FPP at http://localhost:8080
```

## Usage

### Initial Setup

1. After installation, navigate to `Status/Control → Plugins → Tailscale`
2. The plugin will show "Authentication Required" status
3. Click "Connect" to generate an authentication URL
4. Click the authentication link and log in with your Tailscale account
5. Authorize the device
6. Return to the FPP interface - you should now see "Connected to Tailscale"

### Configuration Options

- **Auto-connect on boot**: Automatically connect to Tailscale when FPP starts
- **Accept subnet routes**: Allow access to other devices on your Tailscale network
- **Device Hostname**: Set a custom hostname for your FPP device in Tailscale

### Accessing FPP via Tailscale

Once connected:

1. Install Tailscale on your client device (phone, laptop, etc.)
2. Connect to your Tailscale network
3. Find your FPP device's Tailscale IP in the plugin interface
4. Access FPP using: `http://<tailscale-ip>`

Example: `http://100.64.1.5`

## Docker Testing Setup

Create a `docker-compose.yml` file for testing:

```yaml
version: '3.8'

services:
  fpp:
    image: falconchristmas/fpp:latest
    container_name: fpp-test
    privileged: true
    network_mode: host
    volumes:
      - ./fpp-tailscale-plugin:/opt/fpp/plugins/fpp-tailscale
      - fpp-config:/home/fpp/media/config
      - fpp-media:/home/fpp/media
      - /dev:/dev
      - /sys:/sys
    environment:
      - TZ=America/New_York
    ports:
      - "8080:80"
      - "8443:443"

volumes:
  fpp-config:
  fpp-media:
```

Start the container:

```bash
docker-compose up -d
```

Note: For full Tailscale functionality in Docker, you may need to run in privileged mode or use Tailscale's userspace networking mode.

## Troubleshooting

### Plugin won't install
- Ensure you have internet connectivity
- Check that FPP has sufficient disk space
- Verify FPP version is 7.0 or later

### Can't authenticate
- Verify you can reach login.tailscale.com
- Check firewall settings
- Try generating a new auth URL by clicking "Connect" again

### Connection drops
- Check Tailscale daemon status: `sudo systemctl status tailscaled`
- Review logs in the plugin interface
- Verify network connectivity

### Docker-specific issues
- Ensure container is running in privileged mode
- Check that Tailscale can access `/dev/net/tun`
- Consider using Tailscale userspace mode in containers

## File Structure

```
fpp-tailscale/
├── plugin_info.json       # Plugin metadata
├── plugin_setup          # Installation and lifecycle script
├── index.html            # Web UI
├── api.php              # Backend API
├── config.json          # Configuration (created on first run)
└── README.md            # This file
```

## Configuration File

Located at `/opt/fpp/plugins/fpp-tailscale/config.json`:

```json
{
    "auto_connect": false,
    "accept_routes": false,
    "advertise_exit": false,
    "hostname": "fpp-player"
}
```

## Logs

View logs at:
- Via web UI: Plugin interface → Logs section
- Via SSH: `/var/log/fpp-tailscale.log`

## Security Considerations

- Tailscale uses WireGuard encryption for all traffic
- Only devices in your Tailscale network can access your FPP
- Use Tailscale ACLs to further restrict access if needed
- Keep FPP and Tailscale updated for latest security patches

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## Support

- FPP Forums: https://falconchristmas.com/forum/
- Tailscale Docs: https://tailscale.com/kb/
- GitHub Issues: [Your repo URL]

## License

This plugin is released under the MIT License.

## Credits

Developed for the FPP community. Tailscale® is a trademark of Tailscale Inc.

## Changelog

### v1.0.0 (Initial Release)
- Basic Tailscale integration
- Web-based management interface
- Auto-connect on boot support
- Configuration management
- Logging support
- Docker compatibility
