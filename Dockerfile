FROM falconchristmas/fpp:latest

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Create necessary directories
RUN mkdir -p /var/lib/tailscale \
    && mkdir -p /opt/fpp/plugins/fpp-tailscale \
    && touch /var/log/fpp-tailscale.log \
    && chmod 666 /var/log/fpp-tailscale.log

# Set up Tailscale state directory
ENV TAILSCALE_STATE_DIR=/var/lib/tailscale

# Copy plugin files (will be overridden by volume mount in docker-compose)
COPY . /opt/fpp/plugins/fpp-tailscale/

# Make plugin_setup executable
RUN chmod +x /opt/fpp/plugins/fpp-tailscale/plugin_setup

# Install the plugin
RUN /opt/fpp/plugins/fpp-tailscale/plugin_setup install || true

# Expose FPP ports
EXPOSE 80 443

# Start script that runs both FPP and Tailscale
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
