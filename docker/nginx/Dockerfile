# =============================================================================
# USCIS Case Tracker — Nginx Reverse Proxy Dockerfile
# =============================================================================
# Builds an Nginx reverse proxy that masks Oracle APEX/ORDS URLs.
#
# The standard nginx:alpine image ships with ngx_http_sub_module (sub_filter)
# compiled in, so no custom build is required.
#
# Usage:
#   docker build -t uscis-nginx-proxy ./docker/nginx
#   docker run -p 80:80 --env-file docker/.env uscis-nginx-proxy
#
# Or via docker compose:
#   docker compose -f docker/docker-compose.yml up
# =============================================================================

FROM nginx:1.27-alpine

LABEL maintainer="USCIS Case Tracker <zlovtnik>"
LABEL description="Nginx reverse proxy for Oracle APEX URL masking"

# Install envsubst (part of gettext) for environment variable substitution
# in Nginx config templates, and remove the default Nginx site.
RUN apk add --no-cache gettext && rm -f /etc/nginx/conf.d/default.conf

# Copy our template config (uses ${VAR} placeholders)
COPY default.conf /etc/nginx/templates/default.conf.template

# Custom entrypoint: envsubst resolves env vars into the live config,
# then starts Nginx.  The official nginx image entrypoint handles this
# automatically for files in /etc/nginx/templates/*.template.

# --- Environment variable defaults ------------------------------------------
# These can be overridden at runtime via docker run --env, docker-compose
# environment:, or an .env file.
ENV ORDS_HOST=ords \
    ORDS_PORT=8080 \
    ORDS_SCHEME=http \
    PUBLIC_DOMAIN=localhost \
    PUBLIC_PATH=/uscis \
    ORDS_WORKSPACE=uscis_app \
    APEX_APP_ALIAS=uscis

# Expose HTTP (add 443 if you terminate TLS here)
EXPOSE 80

# Health check — hits the /health endpoint we defined in the config
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost/health || exit 1

# The official nginx image entrypoint runs envsubst on templates then starts
# nginx.  No custom CMD needed.
