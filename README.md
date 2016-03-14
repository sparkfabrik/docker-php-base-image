# Docker PHP base images

## Packages

### PHP Modules

* soap
* gd
* mbstring
* pdo
* pdo_mysql
* zip
* intl
* pcntl
* xdebug (not activated by default)

### Tools

* XDEBUG 2.4.0
* DRUSH 8.0.5
* VAR_DUMPER 3.0.3
* GOSU 1.7
* MAILHOG v0.1.9
* BLACKFIRE (latest)
* NGROK (latest)

### Supervisord

This container is a multi-process container, handled by supervisord.
Configuration file `config/docker/supervisord/supervisord.conf`

Running processes:

* apache
* rsyslogd
* cron

### Cron

The cron expect a file inside `/etc/cron.d/cron` like this:

```
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/30 * * * * root cd /var/www/html && bin/drush cron >/dev/null 2>&1
```

The example above will execute `drush cron` every 30 minutes.

### Logs

#### Apache

Everything is routed to `stdout`, you can use "docker logs -f <container-id>" to see apache logs.

```
ErrorLog /dev/stdout
CustomLog /dev/stdout combined
```

### PHP

PHP is configured through "docker.ini" to write errors to a log file, located at "/tmp/php.err.log".
You can read them by using the following command: `docker exec -it <container-id> tail -F /tmp/php.err.log`


### Timezone

Europe/Rome (yay!)



