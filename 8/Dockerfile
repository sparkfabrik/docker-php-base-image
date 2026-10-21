ARG PHPVER=8.5.7-fpm-alpine3.24

FROM golang:1.26-alpine3.24 AS mailhog

# Install mailhog.
ENV MAILHOG_VERSION=1.0.1
RUN apk add git && \
    go install github.com/mailhog/MailHog@v${MAILHOG_VERSION} && \
    mv /go/bin/MailHog /go/mailhog

# Build PHP from the php.net source tarball instead of using the Docker Hub php
# image, so a new PHP release does not wait for the official image on every
# architecture. This stage mirrors the docker-library/php Alpine FPM image
# (8.x/alpine3.24/fpm/Dockerfile at e3eaff845f7a9f7259c31da54dce0320b47a3bbd);
# the docker-php-* helpers in php-source/ are copied verbatim from it.
# PHPVER (<version>-fpm-alpine<alpine>) selects both the Alpine release and the
# PHP version. Each version needs its tarball sha256 in php-source/sha256sums
# and its release manager keys in php-source/gpg-keys.
FROM alpine:${PHPVER##*-alpine} AS php

ARG PHPVER

# dependencies required for running "phpize"
# these get automatically installed and removed by "docker-php-ext-*" (unless they're already installed)
ENV PHPIZE_DEPS="autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c"

# persistent / runtime deps
RUN apk add --no-cache \
		ca-certificates \
		curl \
		openssl \
		tar \
		xz

# ensure www-data user exists
RUN set -eux; \
	adduser -u 82 -D -S -G www-data www-data
# 82 is the standard uid/gid for "www-data" in Alpine
# https://git.alpinelinux.org/aports/tree/main/apache2/apache2.pre-install?h=3.14-stable
# https://git.alpinelinux.org/aports/tree/main/lighttpd/lighttpd.pre-install?h=3.14-stable
# https://git.alpinelinux.org/aports/tree/main/nginx/nginx.pre-install?h=3.14-stable

ENV PHP_INI_DIR=/usr/local/etc/php
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
# allow running as an arbitrary user (https://github.com/docker-library/php/issues/743)
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# https://github.com/docker-library/php/issues/272
# -D_LARGEFILE_SOURCE and -D_FILE_OFFSET_BITS=64 (https://www.php.net/manual/en/intro.filesystem.php)
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ENV PHP_VERSION=${PHPVER%%-*}
ENV PHP_URL="https://www.php.net/distributions/php-${PHP_VERSION}.tar.xz" PHP_ASC_URL="https://www.php.net/distributions/php-${PHP_VERSION}.tar.xz.asc"

# Download the tarball and verify both its pinned sha256 and its release
# manager GPG signature before anything is built from it.
RUN --mount=type=bind,source=php-source,target=/tmp/php-source \
	set -eux; \
	\
	case "$PHPVER" in \
		"${PHP_VERSION}-fpm-alpine"*) ;; \
		*) echo >&2 "error: PHPVER '$PHPVER' is not <version>-fpm-alpine<alpine>"; exit 1 ;; \
	esac; \
	case "$(cat /etc/alpine-release)" in \
		"${PHPVER##*-alpine}" | "${PHPVER##*-alpine}".*) ;; \
		*) echo >&2 "error: Alpine $(cat /etc/alpine-release) does not match PHPVER '$PHPVER'"; exit 1 ;; \
	esac; \
	PHP_SHA256="$(awk -v f="php-${PHP_VERSION}.tar.xz" '$2 == f { print $1 }' /tmp/php-source/sha256sums)"; \
	GPG_KEYS="$(awk -v m="${PHP_VERSION%.*}" '$1 == m { $1 = ""; print }' /tmp/php-source/gpg-keys)"; \
	if [ -z "$PHP_SHA256" ] || [ -z "$GPG_KEYS" ]; then \
		echo >&2 "error: php-source/ has no sha256 or GPG keys for PHP $PHP_VERSION"; \
		exit 1; \
	fi; \
	\
	apk add --no-cache --virtual .fetch-deps gnupg; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	curl -fsSL -o php.tar.xz "$PHP_URL"; \
	\
	echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
	\
	curl -fsSL -o php.tar.xz.asc "$PHP_ASC_URL"; \
	export GNUPGHOME="$(mktemp -d)"; \
	for key in $GPG_KEYS; do \
		gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	done; \
	gpg --batch --verify php.tar.xz.asc php.tar.xz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	\
	apk del --no-network .fetch-deps

COPY php-source/docker-php-source /usr/local/bin/

RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		argon2-dev \
		coreutils \
		curl-dev \
		gnu-libiconv-dev \
		libsodium-dev \
		libxml2-dev \
		linux-headers \
		oniguruma-dev \
		openssl-dev \
		readline-dev \
		sqlite-dev \
	; \
	\
# make sure musl's iconv doesn't get used (https://www.php.net/manual/en/intro.iconv.php)
	rm -vf /usr/include/iconv.h; \
	\
	export \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
# https://github.com/php/php-src/blob/d6299206dd828382753453befd1b915491b741c6/configure.ac#L1496-L1511
		PHP_BUILD_PROVIDER='https://github.com/docker-library/php' \
		PHP_UNAME='Linux - Docker' \
	; \
	docker-php-source extract; \
	cd /usr/src/php; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	case "$gnuArch" in \
		'i686-linux-'*) \
			# php zend jit assumes SSE registers, xmm0-7, are available (and "Pentium4"/SSE2 is a reasonable baseline)
			# https://github.com/php/php-src/pull/22832
			# so, allow it and use SSE/SSE2 floating-point unit instead of the legacy stack
			export \
				CFLAGS="$CFLAGS -msse2 -mfpmath=sse" \
				CPPFLAGS="$CPPFLAGS -msse2 -mfpmath=sse" \
			; \
			;; \
	esac; \
	test "$PHP_INI_DIR" != "${PHP_INI_DIR%/php}"; \
	./configure \
		--build="$gnuArch" \
		--sysconfdir="${PHP_INI_DIR%/php}" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		\
# make sure invalid --configure-flags are fatal errors instead of just warnings
		--enable-option-checking=fatal \
		\
# https://github.com/docker-library/php/issues/439
		--with-mhash \
		\
# https://github.com/docker-library/php/issues/822
		--with-pic \
		\
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
		--enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
		--enable-mysqlnd \
# https://wiki.php.net/rfc/argon2_password_hash
		--with-password-argon2 \
# https://wiki.php.net/rfc/libsodium
		--with-sodium=shared \
# always build against system sqlite3 (https://github.com/php/php-src/commit/6083a387a81dbbd66d6316a3a12a63f06d5f7109)
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
		\
		--with-curl \
		--with-iconv=/usr \
		--with-openssl \
		--with-readline \
		--with-zlib \
		\
# https://github.com/bwoebi/phpdbg-docs/issues/1#issuecomment-163872806 ("phpdbg is primarily a CLI debugger, and is not suitable for debugging an fpm stack.")
		--disable-phpdbg \
		\
# in PHP 7.4+, the pecl/pear installers are officially deprecated (requiring an explicit "--with-pear")
		--with-pear \
		\
		\
		--disable-cgi \
		\
		--enable-fpm \
		--with-fpm-user=www-data \
		--with-fpm-group=www-data \
	; \
	make -j "$(nproc)"; \
	find -type f -name '*.a' -delete; \
	make install; \
	find \
		/usr/local \
		-type f \
		-perm '/0111' \
		-exec sh -euxc ' \
			strip --strip-all "$@" || : \
		' -- '{}' + \
	; \
	make clean; \
	\
# https://github.com/docker-library/php/issues/692 (copy default example "php.ini" files somewhere easily discoverable)
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	\
	cd /; \
	docker-php-source delete; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache $runDeps; \
	\
	apk del --no-network .build-deps; \
	\
# update pecl channel definitions https://github.com/docker-library/php/issues/443
# pecl.php.net may be unavailable; the image does not depend on it, so a failed
# or slow update only leaves the bundled channel definitions in place.
	timeout 60 pecl update-channels || echo >&2 'warning: pecl update-channels failed'; \
	rm -rf /tmp/pear ~/.pearrc; \
	\
# smoke test
	php --version

COPY php-source/docker-php-ext-* php-source/docker-php-entrypoint /usr/local/bin/

# sodium was built as a shared module (so that it can be replaced later if so desired), so let's enable it too (https://github.com/docker-library/php/issues/598)
RUN docker-php-ext-enable sodium

# enable OPcache by default (https://wiki.php.net/rfc/make_opcache_required)
# Upstream does this for PHP < 8.5; from 8.5 OPcache is built in statically and
# there is no opcache.so to enable.
RUN if [ -f "$(php -r 'echo ini_get("extension_dir");')/opcache.so" ]; then \
		docker-php-ext-enable opcache; \
	fi

ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www/html

RUN set -eux; \
	cd "${PHP_INI_DIR%/php}"; \
	\
	cp -v php-fpm.conf.default php-fpm.conf; \
	cp -v php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	\
	# comment out localhost-only listen address
	grep -E '^listen = 127.0.0.1:9000' php-fpm.d/www.conf; \
	sed -ri 's/^(listen = 127.0.0.1:9000)/;\1/' php-fpm.d/www.conf; \
	grep -E '^;listen = 127.0.0.1:9000' php-fpm.d/www.conf; \
	\
	{ \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
		echo; echo '; https://github.com/docker-library/php/pull/725#issuecomment-443540114'; echo 'log_limit = 8192'; \
		echo; \
		echo '[www]'; \
		echo '; php-fpm closes STDOUT on startup, so sending logs to /proc/self/fd/1 does not work.'; \
		echo '; https://bugs.php.net/bug.php?id=73886'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo 'clear_env = no'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
		echo 'decorate_workers_output = no'; \
		echo; \
		echo '; default listen address for easy override in later php-fpm.d/*.conf files'; \
		echo 'listen = 9000'; \
	} | tee php-fpm.d/docker.conf; \
	{ \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '; the [www] ini section below is for backwards compatibility and will be removed in 8.6+'; \
		echo '[www]'; \
	} | tee php-fpm.d/zz-docker.conf; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	{ \
		echo '; https://github.com/docker-library/php/issues/878#issuecomment-938595965'; \
		echo 'fastcgi.logging = Off'; \
	} > "$PHP_INI_DIR/conf.d/docker-fpm.ini"

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT

EXPOSE 9000
CMD ["php-fpm"]

FROM php AS dist

# Build target arch passed by BuildKit
ARG TARGETARCH

# Pass inexistent UUID (e.g.: 1001) to enhance the container security
ARG user=root

# Default php configurations values.
ENV PHP_MEMORY_LIMIT=64M
ENV PHP_TIMEZONE=Europe/Rome
ENV PHP_REALPATH_CACHE_SIZE=2M
ENV PHP_UPLOAD_MAX_FILE_SIZE=32M
ENV PHP_POST_MAX_SIZE=32M
ENV PHP_MAX_EXECUTION_TIME=30
ENV BLACKFIRE_HOST=blackfire
ENV BLACKFIRE_PORT=8307
ENV PHP_EXPOSE_PHP=0
ENV PHP_SESSION_UPLOAD_PROGRESS_ENABLED=0

# FPM Configurations.
ENV PHP_FPM_PM_TYPE=dynamic
ENV PHP_FPM_MAX_CHILDREN=5
ENV PHP_FPM_START_SERVERS=2
ENV PHP_FPM_MIN_SPARE_SERVERS=1
ENV PHP_FPM_MAX_SPARE_SERVERS=3
ENV PHP_FPM_PM_STATUS_PATH=/status

ENV XDEBUG_VERSION=3.5.3
ENV MEMCACHE_VERSION=3.4.0
ENV PHPREDIS_VERSION=6.3.0
ENV APCU_VERSION=5.1.28
# PECL extensions are built from their upstream GitHub release tags, not from
# pecl.php.net. Each archive is pinned by sha256: update the checksum together
# with the version. Like `pecl install`, ext_build only installs the shared
# object; conf/ and the entrypoint decide which extensions are loaded.
RUN ext_build() { \
        name="$1" url="$2" sha256="$3" && shift 3 && \
        mkdir -p "/usr/src/${name}" && \
        curl -fsSL --retry 5 -o "/tmp/${name}.tar.gz" "${url}" && \
        echo "${sha256} */tmp/${name}.tar.gz" | sha256sum -c - && \
        tar -xzf "/tmp/${name}.tar.gz" -C "/usr/src/${name}" --strip-components=1 && \
        (cd "/usr/src/${name}" && phpize && ./configure "$@" && make -j "$(nproc)" && make install) && \
        rm -rf "/usr/src/${name}" "/tmp/${name}.tar.gz"; \
    } && \
    export XDEBUG_DEPS="linux-headers" && \
    export PHP_EXTRA_DEPS="libxml2-dev icu-dev libmemcached-dev cyrus-sasl-dev libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev libzip-dev oniguruma-dev libwebp-dev libldap openldap-dev openssl-dev" && \
    apk update && \
    apk add ${PHP_EXTRA_DEPS} ${PHPIZE_DEPS} ${XDEBUG_DEPS} gettext && \
    docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-webp=/usr/include && \
    docker-php-ext-configure ldap && \
    export OPENSSL_LIBS="-L/usr -lssl -lcrypto -lz" && export OPENSSL_CFLAGS="-I/usr/include" && \
    if php -r 'exit(version_compare(PHP_VERSION, "8.4", "<") ? 0 : 1);'; then \
        docker-php-ext-configure ftp --with-openssl-dir=/usr/include/; \
    else \
        docker-php-ext-configure ftp --with-ftp-ssl; \
    fi && \
    docker-php-ext-install bcmath gd intl mbstring pcntl pdo pdo_mysql soap zip ldap ftp && \
    ext_build xdebug "https://github.com/xdebug/xdebug/archive/refs/tags/${XDEBUG_VERSION}.tar.gz" \
        954e56021668121ecc50b92d2ad1ce945f22ecf81ffc5bb5835219485b12ef5f && \
    ext_build redis "https://github.com/phpredis/phpredis/archive/refs/tags/${PHPREDIS_VERSION}.tar.gz" \
        cb8f81df1a275599e4f8ddcfec7e1f65ed1953e6f5673649149fd680ebff4cad && \
    # igbinary 3.2.16, the latest stable release, does not build on PHP 8.5, so
    # 8.5 uses 3.2.17RC1 (the version pecl installed there before).
    if php -r 'exit(version_compare(PHP_VERSION, "8.5", "<") ? 0 : 1);'; then \
        ext_build igbinary "https://github.com/igbinary/igbinary/archive/refs/tags/3.2.16.tar.gz" \
            941f1cf2ccbecdc1c221dbfae9213439d334be5d490a2f3da2be31e8a00b0cdb; \
    else \
        ext_build igbinary "https://github.com/igbinary/igbinary/archive/refs/tags/3.2.17RC1.tar.gz" \
            d563482bd3f623a08bd38ecab1da69e2f8c0f87a781f8b395dd0a95c9959d6e4; \
    fi && \
    # pecl ignored --disable-memcached-sasl, so the images have always shipped
    # memcached with SASL support; the configure defaults keep it that way.
    ext_build memcached "https://github.com/php-memcached-dev/php-memcached/archive/refs/tags/v${MEMCACHE_VERSION}.tar.gz" \
        10b98a0fdc3ce9ab823db59e8935f068de87e374728871a1efacdadd8c7807d1 && \
    ext_build apcu "https://github.com/krakjoe/apcu/archive/refs/tags/v${APCU_VERSION}.tar.gz" \
        0e60ba9d0fa4021c57a70c071f3d8f71de236275d084e560d5959fec4edd8c32 && \
    apk del ${PHPIZE_DEPS} ${XDEBUG_DEPS} && \
    rm -rf /var/cache/apk/*

# Install blackfire client.
ENV BLACKFIRE_CLIENT_VERSION=2026.6.0
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

# Enable OPcache as a Zend extension only when the parent image has not already
# done so. The official php image enables OPcache by default (ships
# docker-php-ext-opcache.ini) since docker-library/php#1587; parents built
# before that, and any without the shared opcache.so, still need the manual
# loader. Keying off the ini file keeps OPcache enabled everywhere while
# avoiding the "Cannot load Zend OPcache - it was already loaded" double-load.
RUN if [ ! -f /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini ] \
        && [ -f "$(php -r 'echo ini_get("extension_dir");')/opcache.so" ]; then \
        echo "zend_extension=opcache.so" > /usr/local/etc/php/conf.d/00-opcache-load.ini; \
    fi

# Make folders writable for the root group
RUN chmod 775 /usr/local/etc/php && \
    chmod 775 /usr/local/etc/php/conf.d && \
    chmod 775 /usr/local/etc/php-fpm.d && \
    chmod 775 /templates

# Go to target user
USER $user

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["php-fpm"]

FROM dist AS dev

# Build target arch passed by BuildKit
ARG TARGETARCH

# Pass inexistent UUID (e.g.: 1001) to enhance the container security
ARG user=root

ARG COMPOSER_VERSION

USER root

ENV COMPOSER_MEMORY_LIMIT=-1
ENV COMPOSER_HOME=/composer-libs

RUN apk add --no-cache patch rsync git

RUN mkdir $COMPOSER_HOME \
    && chmod -R 775 $COMPOSER_HOME \
    && curl -L -o /usr/local/bin/composer https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar \
    && chmod +x /usr/local/bin/composer \
    && echo "PS1='\[\033[1;36m\]\u\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] '" >> /etc/profile \
    && echo "export TERM=xterm" >> /etc/profile

# Go to target user
USER $user
