#!/bin/sh
export PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-"128M"}
export PHP_TIMEZONE=${PHP_TIMEZONE:-"Europe/Rome"}
export PHP_OPCACHE_ENABLE=${PHP_OPCACHE_ENABLE:-1}
export PHP_OPCACHE_MEMORY=${PHP_OPCACHE_MEMORY:-64}

# Services.
export MAILHOG_ENABLE=${MAILHOG_ENABLE:-0}
export REDIS_ENABLE=${REDIS_ENABLE:-0}
export MEMCACHED_ENABLE=${MEMCACHED_ENABLE:-0}
export XDEBUG_ENABLE=${XDEBUG_ENABLE:-0}

# Services configurations.
export MAILHOG_HOST=${MAILHOG_HOST:-"mail"}
export MAILHOG_PORT=${MAILHOG_PORT:-1025}

# Blackfire configurations.
export BLACKFIRE_APM_ENABLED=${BLACKFIRE_APM_ENABLED:-0}

if [ "${MEMCACHED_ENABLE}" = "1" ]; then
	cp /usr/local/etc/php/conf.disabled/memcached.ini /usr/local/etc/php/conf.d/memcached.ini
else
	rm -f /usr/local/etc/php/conf.d/memcached.ini || true
fi

if [ "${REDIS_ENABLE}" = "1" ]; then
	cp /usr/local/etc/php/conf.disabled/redis.ini /usr/local/etc/php/conf.d/redis.ini
else
	rm -f /usr/local/etc/php/conf.d/redis.ini || true
fi

if [ "${MAILHOG_ENABLE}" = "1" ]; then
	cp /usr/local/etc/php/conf.disabled/mailhog.ini /usr/local/etc/php/conf.d/mailhog.ini
else
	rm -f /usr/local/etc/php/conf.d/mailhog.ini || true
fi

if [ "${XDEBUG_ENABLE}" = "1" ]; then
	cp /usr/local/etc/php/conf.disabled/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
else
	rm -f /usr/local/etc/php/conf.d/xdebug.ini || true
fi

# php-fpm template env subst.
envsubst < /templates/zz2-docker-custom.conf > /usr/local/etc/php-fpm.d/zz2-docker-custom.conf

exec "$@"


