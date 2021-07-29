# Docker PHP base images

[![](https://images.microbadger.com/badges/image/sparkfabrik/docker-php-base-image.svg)](https://microbadger.com/images/sparkfabrik/docker-php-base-image 'Get your own image badge on microbadger.com')

## Packages

### PHP Modules

- bcmath
- gd
- intl
- mbstring
- memcached (not activated by default)
- pcntl
- pdo
- pdo_mysql
- redis (not activated by default)
- soap
- xdebug (not activated by default)
- zip

### Tools

- XDEBUG 2.9.0
- MAILHOG v0.1.9
- BLACKFIRE (latest)

## Env variables

The entrypoint file contains a list of environment variables that will be replaced in the configuration files.

### Base PHP configuration

- `PHP_MEMORY_LIMIT`: maximum amount of memory in bytes that a script is allowed to allocate (default `128M`)
- `PHP_TIMEZONE`: timezone used by all date/time functions in a script (default `Europe/Rome`)
- `PHP_OPCACHE_ENABLE`: enable the opcode cache (default `1`)
- `PHP_OPCACHE_MEMORY`: the size of the shared memory storage used by OPcache, in megabytes (default `64`)

### Services

- `REDIS_ENABLE`: enable redis extension (default `0`)
- `MEMCACHED_ENABLE`: enable memcached extension (default `0`)
- `XDEBUG_ENABLE`: enable xdebug extension (default `0`; you need to set `XDEBUG_REMOTE_HOST` env variable also)
- `MAILHOG_ENABLE`: change the default `sendmail_path` with the `mailhog` command (default `0`)
- `LDAP_ENABLE`: enable ldap extension (default `0`)

### Services configurations

- `MAILHOG_HOST`: mailhog smtp address (default `mail`)
- `MAILHOG_PORT`: mailhog smtp port (default `1025`)

## Rootless feature

You can use `build-arg` to specify a `user` argument different from `root` to build the image with this feature.
If you provide a non-root user the container will drop its privileges targeting the specified user.
We have inserted the specific make targets with dedicated image suffix tags (`-rootless`) for these flavours.

You can find some more information [here](https://docs.bitnami.com/tutorials/work-with-non-root-containers/).

## Tests

In the `tests` folder you can find the `image_verify.sh` script which is used to perform the end-to-end tests of the images.
The script accepts a file as input (`--source`) which is used to configure the expectations.
The expectations are defined by `key-value pairs` like the example below:

```bash
PHP_MEMORY_LIMIT="64M"
PHP_TIMEZONE="Europe/Rome"
MODULE_REDIS_ENABLE="1"
MODULE_MEMCACHED_ENABLE="0"
```

You can also test the which user the container was launched with by using the `--user` input.
If you build the image with a non existent user you can test it with the string `unknown uid ${UUID}`.
