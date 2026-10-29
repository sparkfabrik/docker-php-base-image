# Docker PHP base images

## Packages

### PHP Modules

- apcu
- bcmath
- ftp
- gd
- grpc (not activated by default, see [gRPC](#grpc))
- igbinary
- intl
- ldap (not activated by default)
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

- XDEBUG 3.5.3
- MAILHOG v1.0.1
- BLACKFIRE (client 2026.6.0, probe latest)

## Env variables

The entrypoint file contains a list of environment variables that will be replaced in the configuration files.

### Base PHP configuration

- `PHP_MEMORY_LIMIT`: maximum amount of memory in bytes that a script is allowed to allocate (default `128M`)
- `PHP_TIMEZONE`: timezone used by all date/time functions in a script (default `Europe/Rome`)
- `PHP_OPCACHE_ENABLE`: enable the opcode cache (default `1`)
- `PHP_OPCACHE_MEMORY`: the size of the shared memory storage used by OPcache, in megabytes (default `64`)
- `PHP_SESSION_UPLOAD_PROGRESS_ENABLED`: enable the native session upload progress tracking, `session.upload_progress.enabled` (default `0`)

### PHP-FPM pool configuration

- `PHP_FPM_REQUEST_TERMINATE_TIMEOUT`: wall-clock time after which a worker serving a single request is killed, e.g. `60s` (default `0`, disabled)
- `PHP_FPM_REQUEST_SLOWLOG_TIMEOUT`: wall-clock time after which the PHP backtrace of a request is written to the container stderr, e.g. `10s` (default `0`, disabled). The root flavour needs the `SYS_PTRACE` capability to write the backtrace, because the FPM master runs as root and the workers as `www-data`; without it FPM logs `failed to ptrace(ATTACH) child` and only the slow-request warning. The rootless flavour needs no extra capability.

### Services

- `REDIS_ENABLE`: enable redis extension (default `0`)
- `MEMCACHED_ENABLE`: enable memcached extension (default `0`)
- `XDEBUG_ENABLE`: enable xdebug extension (default `0`; you need to set `XDEBUG_REMOTE_HOST` env variable also)
- `MAILHOG_ENABLE`: change the default `sendmail_path` with the `mailhog` command (default `0`)
- `LDAP_ENABLE`: enable ldap extension (default `0`)

### Services configurations

- `MAILHOG_HOST`: mailhog smtp address (default `mail`)
- `MAILHOG_PORT`: mailhog smtp port (default `1025`)

## gRPC

The `grpc` extension (needed, for example, by the Google Cloud Firestore SDK) is installed but not loaded, and has no `*_ENABLE` variable. A downstream image loads it with an ini file in `/usr/local/etc/php/conf.d/`:

```ini
extension=grpc
```

Loading it from an ini file, instead of from the entrypoint, also works for containers that override the entrypoint, such as Kubernetes Jobs with a `command`.

Its defaults are in `conf.d/00-grpc.ini`:

- `grpc.enable_fork_support=1`: a child forked after the parent opened a gRPC channel fails with an exception instead of hanging on a gRPC lock (fork before opening a channel).
- `grpc.poll_strategy=epoll1`: fork support needs `epoll1` or `poll`.

To change them, or set any other value, use an ini file of your own. PHP reads `conf.d` in alphabetical order and the last value wins, and `00-grpc.ini` sorts first, so any other file overrides it, including the `docker-php-ext-grpc.ini` that `docker-php-ext-enable grpc` writes.

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
