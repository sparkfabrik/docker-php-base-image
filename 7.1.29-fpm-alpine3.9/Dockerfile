FROM golang:1.16.6-alpine3.14 as mailhog

# Install mailhog.
ENV MAILHOG_VERSION 0.2.1
RUN apk add git && \
    go get github.com/mailhog/MailHog@v${MAILHOG_VERSION} && \
    mv /go/bin/MailHog /go/mailhog

FROM php:7.1.29-fpm-alpine3.9

# Build target arch passed by BuildKit
ARG TARGETARCH

# Pass inexistent UUID (e.g.: 1001) to enhance the container security
ARG user=root

# Default php configurations values.
ENV PHP_MEMORY_LIMIT 64M
ENV PHP_TIMEZONE=Europe/Rome
ENV PHP_REALPATH_CACHE_SIZE 2M
ENV PHP_UPLOAD_MAX_FILE_SIZE 32M
ENV PHP_POST_MAX_SIZE 32M
ENV PHP_MAX_INPUT_VARS 1000
ENV PHP_MAX_EXECUTION_TIME 30
ENV BLACKFIRE_HOST=${BLACKFIRE_HOST:-blackfire}

# FPM Configurations.
ENV PHP_FPM_MAX_CHILDREN 5
ENV PHP_FPM_START_SERVERS 2
ENV PHP_FPM_MIN_SPARE_SERVERS 1
ENV PHP_FPM_MAX_SPARE_SERVERS 3

ENV XDEBUG_VERSION 2.7.2
ENV MEMCACHE_VERSION 3.1.3
ENV PHPREDIS_VERSION 4.3.0
ENV PHP_EXTRA_DEPS libxml2-dev icu-dev libmemcached-dev cyrus-sasl-dev libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev libwebp-dev
RUN apk update && \
    apk add ${PHP_EXTRA_DEPS} ${PHPIZE_DEPS} gettext && \
    docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-png-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-webp-dir=/usr/include && \
    docker-php-ext-install bcmath gd intl mbstring pcntl pdo pdo_mysql soap zip && \
    pecl install xdebug-${XDEBUG_VERSION} && \
    pecl install redis-${PHPREDIS_VERSION} && \
    pecl install igbinary memcached-${MEMCACHE_VERSION} --disable-memcached-sasl && \
    apk del ${PHPIZE_DEPS} && \
    rm -rf /var/cache/apk/*

# Install blackfire client.
ENV BLACKFIRE_CLIENT_VERSION 2.4.3
RUN mkdir -p /tmp/blackfire && \
    curl -A "Docker" -L https://packages.blackfire.io/binaries/blackfire/${BLACKFIRE_CLIENT_VERSION}/blackfire-linux_${TARGETARCH}.tar.gz | tar zxp -C /tmp/blackfire && \
    mv /tmp/blackfire/blackfire /usr/bin/blackfire && \
    rm -Rf /tmp/blackfire

# Install blackfire probe.
ENV BLACKFIRE_PROBE_VERSION 1.64.0
RUN curl -A "Docker" -o /tmp/blackfire-php-alpine_${TARGETARCH}-php-71.so -D - -L -s https://packages.blackfire.io/binaries/blackfire-php/${BLACKFIRE_PROBE_VERSION}/blackfire-php-alpine_${TARGETARCH}-php-71.so \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://\${BLACKFIRE_HOST}:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini

# Copy mailhog from golang image.
COPY --from=mailhog /go/mailhog /usr/local/bin/mailhog
RUN chmod +x /usr/local/bin/mailhog

# Configure entrypoint.
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Configure PHP.
COPY conf/*.ini /usr/local/etc/php/conf.d/
COPY conf.disabled /usr/local/etc/php/conf.disabled
COPY fpm-conf-templates/ /templates/

# Make folders writable for the root group
RUN chmod 775 /usr/local/etc/php && \
    chmod 775 /usr/local/etc/php/conf.d && \
    chmod 775 /usr/local/etc/php-fpm.d && \
    chmod 775 /templates

# Go to target user
USER $user

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["php-fpm"]
