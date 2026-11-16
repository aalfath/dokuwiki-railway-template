# DokuWiki for Railway: the official image, pinned by version and digest.
# Upstream: https://github.com/dokuwiki/docker  (DokuWiki release 2026-07-14c)
FROM dokuwiki/dokuwiki:2026-07-14c@sha256:a289deab45e2d4cbc8b6db1c228955d4dccac0d78da9dcf482adfa12e6641ed1

COPY railway-start.sh /railway-start.sh
COPY railway-install.php /railway-install.php
COPY railway-healthz.conf /etc/apache2/conf-available/railway-healthz.conf
RUN chmod 0755 /railway-start.sh && chmod 0644 /railway-install.php \
 && a2enconf railway-healthz

# Railway sets PORT; Apache listens on it (8080 by default, as upstream).
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/railway-start.sh"]
