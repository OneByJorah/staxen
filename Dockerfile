FROM nginx:1.29-alpine-slim

# Copy only the static landing-page assets
COPY index.html /usr/share/nginx/html/index.html
COPY docs/assets /usr/share/nginx/html/docs/assets

# Harden: run as nginx unprivileged user, drop unnecessary capabilities in compose
RUN chown -R 101:0 /usr/share/nginx/html /var/cache/nginx /var/log/nginx /run && \
    chmod -R g+w /var/cache/nginx /var/log/nginx /run

EXPOSE 80
USER 101

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD ["sh", "-c", "curl -fsS http://localhost/ >/dev/null || exit 1"]

CMD ["nginx", "-g", "daemon off;"]
