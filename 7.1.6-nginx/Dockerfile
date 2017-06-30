FROM php:7.1.6-fpm
MAINTAINER paolo.mainardi@sparkfabrik.com
ENV REFRESHED_AT 2016-06-29

ENV DEBIAN_FRONTEND noninteractive


# System env variables.
ENV XDEBUG_VERSION 2.5.4
ENV DRUSH_VERSION 8.0.5
ENV VAR_DUMPER_VERSION 3.0.3
ENV GOSU_VERSION 1.7
ENV MAILHOG_VERSION v0.1.9
ENV TIMEZONE "Europe/Rome"

ENV php_conf /usr/local/etc/php-fpm.conf
ENV fpm_conf /usr/local/etc/php-fpm.d/www.conf
ENV php_vars /usr/local/etc/php/conf.d/docker-vars.ini

# Install nginx and other packages

RUN apt-get update \
  && apt-get install -y \
  nginx \
  curl \
  cron \
  rsyslog \
  supervisor \
  mysql-client \
  libpng12-dev \
  libjpeg-dev \
  libxml2-dev \
  ruby \
  ruby2.1 \
  ruby2.1-dev\
  git \
  unzip \
  vim \
  libicu-dev \
  libssl-dev \
  && gem install bundler \
  && pecl install xdebug-${XDEBUG_VERSION} \
  && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
  && docker-php-ext-configure intl \
  && docker-php-ext-configure pcntl \
  && docker-php-ext-install soap gd mbstring pdo pdo_mysql zip intl pcntl \
  && echo "${TIMEZONE}" > /etc/timezone \
  && dpkg-reconfigure -f noninteractive tzdata \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



# Copy our nginx config
RUN mv  /etc/nginx/nginx.conf /etc/nginx/nginx.conf.1
RUN rm -f  /etc/nginx/sites-enabled/default
RUN rm -f  /etc/nginx/sites-available/default

ADD config/docker/nginx/nginx.conf /etc/nginx/nginx.conf

# nginx site conf
RUN mkdir -p /etc/nginx/sites-available/ && \
mkdir -p /etc/nginx/sites-enabled/ && \
mkdir -p /etc/nginx/ssl/ && \
rm -Rf /var/www/* && \
mkdir /var/www/html/
ADD config/docker/nginx/nginx-site.conf /etc/nginx/sites-available/default.conf
ADD config/docker/nginx/nginx-site-ssl.conf /etc/nginx/sites-available/default-ssl.conf
RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

# tweak php-fpm config
RUN echo "cgi.fix_pathinfo=0" > ${php_vars} &&\
    echo "upload_max_filesize = 100M"  >> ${php_vars} &&\
    echo "post_max_size = 100M"  >> ${php_vars} &&\
    echo "variables_order = \"EGPCS\""  >> ${php_vars} && \
    echo "memory_limit = 512M"  >> ${php_vars} && \
    sed -i \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 5/pm.max_children = 4/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
        -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        ${fpm_conf}



# Install composer, drush and other tools.
ENV COMPOSER_HOME /composer-libs
RUN mkdir /composer-libs \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer global require symfony/var-dumper:${VAR_DUMPER_VERSION} \
    && chown -R www-data:www-data /composer-libs \
    && curl -fSL "https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar" -o /usr/bin/drush \
    && chmod +x /usr/bin/drush \
    && drush @none dl registry_rebuild-7.x-2.3 \
    && echo "PS1='\[\033[1;36m\]\u\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] '" >> /etc/bash.bashrc \
    && echo "export TERM=xterm" >> /etc/bash.bashrc \
    && echo "umask 000" >> /etc/bash.bashrc \
    && curl -fSL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" -o /usr/bin/gosu

# Install mailhog.
RUN curl -fSL "https://github.com/mailhog/MailHog/releases/download/${MAILHOG_VERSION}/MailHog_linux_amd64" -o /usr/local/bin/mailhog \
    && chmod +x /usr/local/bin/mailhog

## Configure supervisord.
COPY config/docker/supervisord/*.conf /etc/supervisor/conf.d/
#RUN mkdir -p /usr/local/etc/php/apache2 && \


# Configure cron.
COPY config/docker/cron/crontab /etc/cron.d/cron
RUN rm -Rf /etc/cron.daily  && \
    rm -Rf /etc/cron.weekly && \
    rm -Rf /etc/cron.monthly && \
    rm -Rf /etc/cron.hourly && \
    chmod a+x /etc/cron.d/cron

# Install blackfire agent.
#RUN export VERSION=`php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;"` \
#    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/${VERSION} \
#    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
#    && mv /tmp/blackfire-*.so `php -r "echo ini_get('extension_dir');"`/blackfire.so \
#    && echo "extension=blackfire.so\nblackfire.agent_socket=\${BLACKFIRE_PORT}" > $PHP_INI_DIR/apache2/conf.d/blackfire.ini


# Install ngrok.
ADD https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip /ngrok.zip
RUN unzip /ngrok.zip -d /bin && \
 rm -f ngrok.zip && \
 touch /.ngrok

# Add Scripts
ADD config/docker/nginx/letsencrypt-setup /usr/bin/letsencrypt-setup
ADD config/docker/nginx/letsencrypt-renew /usr/bin/letsencrypt-renew
RUN chmod 755 /usr/bin/letsencrypt-setup && chmod 755 /usr/bin/letsencrypt-renew

# Expose nginx.
EXPOSE 80 443

# Execute daemons.
CMD exec supervisord -n
