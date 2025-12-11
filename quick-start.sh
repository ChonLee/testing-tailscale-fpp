#!/bin/bash
#
# Quick Start Script for FPP Tailscale Plugin Testing
#

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "FPP Tailscale Plugin - Quick Start"
echo "=========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

# Determine docker compose command
if docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo "✓ Docker and Docker Compose are installed"
echo ""

# Check if container is already running
if docker ps | grep -q fpp-tailscale-test; then
    echo "Container is already running!"
    echo ""
    echo "Options:"
    echo "  1) View logs"
    echo "  2) Stop container"
    echo "  3) Restart container"
    echo "  4) Exit"
    echo ""
    read -p "Choose an option (1-4): " choice
    
    case $choice in
        1)
            docker logs -f fpp-tailscale-test
            ;;
        2)
            echo "Stopping container..."
            $DOCKER_COMPOSE down
            echo "✓ Container stopped"
            ;;
        3)
            echo "Restarting container..."
            $DOCKER_COMPOSE restart
            echo "✓ Container restarted"
            ;;
        4)
            exit 0
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac
else
    echo "Starting FPP with Tailscale plugin..."
    echo ""
    
    # Create /dev/net/tun if it doesn't exist (needed for Tailscale)
    if [ ! -e /dev/net/tun ]; then
        echo "Creating /dev/net/tun device..."
        sudo mkdir -p /dev/net
        sudo mknod /dev/net/tun c 10 200
        sudo chmod 666 /dev/net/tun
    fi
    
    # Start the container
    $DOCKER_COMPOSE up -d
    
    echo ""
    echo "✓ Container started successfully!"
    echo ""
    echo "=========================================="
    echo "Next Steps:"
    echo "=========================================="
    echo ""
    echo "1. Wait ~30 seconds for FPP to fully start"
    echo ""
    echo "2. Access FPP web interface:"
    echo "   → http://localhost:8080"
    echo ""
    echo "3. Navigate to the Tailscale plugin:"
    echo "   → Status/Control → Plugins → Tailscale"
    echo ""
    echo "4. Click 'Connect' and follow the authentication link"
    echo ""
    echo "5. View logs:"
    echo "   → docker logs -f fpp-tailscale-test"
    echo ""
    echo "=========================================="
    echo ""
    
    # Wait for container to be healthy
    echo "Waiting for FPP to start..."
    sleep 5
    
    # Check if container is running
    if docker ps | grep -q fpp-tailscale-test; then
        echo "✓ Container is running"
        echo ""
        echo "Opening browser in 3 seconds..."
        sleep 3
        
        # Try to open browser
        if command -v xdg-open &> /dev/null; then
            xdg-open http://localhost:8080 2>/dev/null || true
        elif command -v open &> /dev/null; then
            open http://localhost:8080 2>/dev/null || true
        fi
    else
        echo "⚠️  Container may not have started correctly"
        echo "Check logs with: docker logs fpp-tailscale-test"
    fi
fi
