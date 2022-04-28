FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
  apt-get install -y -o APT::Install-Recommends=false -o APT::Install-Suggests=false \
  shellcheck

# Cleanup
RUN apt-get clean -q && apt-get autoremove --purge \
  && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT [ "/docker-entrypoint.sh" ]
