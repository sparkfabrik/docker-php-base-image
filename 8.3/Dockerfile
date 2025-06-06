ARG PHPVER

FROM golang:1.23.0-alpine3.20 as mailhog

# Install mailhog.
ENV MAILHOG_VERSION 1.0.1
RUN apk add git && \
    go install github.com/mailhog/MailHog@v${MAILHOG_VERSION} && \
    mv /go/bin/MailHog /go/mailhog

FROM php:$PHPVER as dist

# Build target arch passed by BuildKit
ARG TARGETARCH

# Pass inexistent UUID (e.g.: 1001) to enhance the container security
ARG user=root

# Default php configurations values.
ENV PHP_MEMORY_LIMIT 64M
ENV PHP_TIMEZONE=Europe/Rome
ENV PHP_REALPATH_CACHE_SIZE 2M
ENV PHP_UPLOAD_MAX_FILE_SIZE 32M
ENV PHP_POST_MAX_SIZE 32M
ENV PHP_MAX_EXECUTION_TIME 30
ENV BLACKFIRE_HOST=${BLACKFIRE_HOST:-blackfire}
ENV BLACKFIRE_PORT=${BLACKFIRE_PORT:-8307}
ENV PHP_EXPOSE_PHP 0

# FPM Configurations.
ENV PHP_FPM_PM_TYPE dynamic
ENV PHP_FPM_MAX_CHILDREN 5
ENV PHP_FPM_START_SERVERS 2
ENV PHP_FPM_MIN_SPARE_SERVERS 1
ENV PHP_FPM_MAX_SPARE_SERVERS 3
ENV PHP_FPM_PM_STATUS_PATH /status

ENV XDEBUG_VERSION 3.3.1
ENV MEMCACHE_VERSION 3.2.0
ENV PHPREDIS_VERSION 5.3.7
RUN export XDEBUG_DEPS="linux-headers" && \
    export PHP_EXTRA_DEPS="libxml2-dev icu-dev libmemcached-dev cyrus-sasl-dev libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev libzip-dev oniguruma-dev libwebp-dev ldb-dev libldap openldap-dev openssl-dev" && \
    apk update && \
    apk add ${PHP_EXTRA_DEPS} ${PHPIZE_DEPS} ${XDEBUG_DEPS} gettext && \
    docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-webp=/usr/include && \
    docker-php-ext-configure ldap && \
    export OPENSSL_LIBS="-L/usr -lssl -lcrypto -lz" && export OPENSSL_CFLAGS="-I/usr/include" && \
    docker-php-ext-configure ftp --with-openssl-dir=/usr/include/ && \
    docker-php-ext-install bcmath gd intl mbstring pcntl pdo pdo_mysql soap zip ldap ftp && \
    pecl install xdebug-${XDEBUG_VERSION} && \
    pecl install redis-${PHPREDIS_VERSION} && \
    pecl install igbinary memcached-${MEMCACHE_VERSION} --disable-memcached-sasl && \
    apk del ${PHPIZE_DEPS} ${XDEBUG_DEPS} && \
    rm -rf /var/cache/apk/*

# Install APCu.
ENV APCU_VERSION 5.1.21
RUN apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS && \
    pecl install apcu-${APCU_VERSION} && \
    apk del .phpize-deps-configure

# Install blackfire client.
ENV BLACKFIRE_CLIENT_VERSION 2.8.1
RUN mkdir -p /tmp/blackfire && \
    curl -A "Docker" -L https://packages.blackfire.io/binaries/blackfire/${BLACKFIRE_CLIENT_VERSION}/blackfire-linux_${TARGETARCH}.tar.gz | tar zxp -C /tmp/blackfire && \
    mv /tmp/blackfire/blackfire /usr/bin/blackfire && \
    rm -Rf /tmp/blackfire

# Install blackfire probe.
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && architecture=$(uname -m) \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/$architecture/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://\${BLACKFIRE_HOST}:${BLACKFIRE_PORT}\nblackfire.apm_enabled=\${BLACKFIRE_APM_ENABLED}\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

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

FROM dist as dev

# Build target arch passed by BuildKit
ARG TARGETARCH

# Pass inexistent UUID (e.g.: 1001) to enhance the container security
ARG user=root

ARG COMPOSER_VERSION

USER root

ENV COMPOSER_MEMORY_LIMIT -1
ENV COMPOSER_HOME /composer-libs

RUN apk add --no-cache patch rsync git

RUN mkdir $COMPOSER_HOME \
    && chmod -R 775 $COMPOSER_HOME \
    && curl -L -o /usr/local/bin/composer https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar \
    && chmod +x /usr/local/bin/composer \
    && echo "PS1='\[\033[1;36m\]\u\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] '" >> /etc/profile \
    && echo "export TERM=xterm" >> /etc/profile

# Go to target user
USER $user
