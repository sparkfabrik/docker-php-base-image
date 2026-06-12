# AGENTS.md

## Project Overview

Builds and publishes the SparkFabrik PHP-FPM base Docker images to `ghcr.io/sparkfabrik/docker-php-base-image`. Each image bundles a pinned PHP version (FPM, Alpine) with a fixed extension set, Composer, MailHog, and the Blackfire client/probe, plus an entrypoint that renders PHP/FPM config from environment variables at container start.

This is an image factory, not an application: there is no root package manager. "Dependencies" are upstream versions pinned in the Dockerfile and the `Makefile`.

**Which versions are built is data, not knowledge — always look it up instead of assuming the current major:**

- `PHP_TAGS` in `.github/workflows/docker-publish.yml` is the single source of truth for the published versions (each entry has `short` = Makefile target suffix, `full` = the PHPVER / image tag).
- The active `build-<x-y-z>:` targets in the `Makefile` mirror it for local builds; list them with `grep -E '^build-[0-9-]+:' Makefile`.

The current major is PHP 8, but treat that as a fact to be re-read, not hardcoded — the same conventions apply when the line moves to 9, 10, etc.

**Tech stack:** multi-stage Dockerfiles (`dist` + `dev` targets), POSIX shell (entrypoint, test harness), GNU Make (task runner), GitHub Actions (CI/publish).

### Layout

- One shared build folder per active major (currently `8/`): `Dockerfile`, `docker-entrypoint.sh`, `conf/` (active php.ini fragments), `conf.disabled/` (opt-in extensions), `fpm-conf-templates/`.
- `scripts/guess_folder.sh` — resolves a `PHPVER` to its folder, falling back full → `major.minor` → `major`, so every minor/patch of a major reuses that major's one folder.
- `tests/` — image end-to-end checks (`image_verify.sh`, `tests_wrapper.sh`, `expectations/`).
- `shellcheck/` — dockerized ShellCheck for `make shellcheck`.
- The numbered `7.x` folders are frozen legacy; do not extend or imitate them.

## Setup

Everything runs in Docker via `make` and `docker buildx`; no local PHP/Composer/extensions. The host needs Docker with Buildx and GNU Make.

```bash
# Build + locally test one version (dist + dev, then the suite).
# Use a version that exists as a Makefile target (see grep above).
make build-<x-y-z>           # e.g. the newest active target
make build-<x-y-z>-rootless  # rootless flavour (uid 1001)

# Generic form, any full tag (this is what CI uses):
make build-template PHPVER=<x.y.z-fpm-alpineX.Y>
make build-rootless-template PHPVER=<x.y.z-fpm-alpineX.Y>
```

The `build-<x-y-z>` targets just set `PHPVER` and delegate to the templates.

## Key Conventions

### Single shared folder (mandatory)

All images of a major are built from ONE folder (currently `8/`). Express per-version differences with build args and conditional shell inside that folder — never by forking it. Adding a patch, a minor, or a whole new major must reuse a shared folder. A separate per-version folder is acceptable only when a difference is genuinely impossible to express with build args, and the reason must be documented. Maintaining near-duplicate folders is explicitly not worth it; the frozen `7.x` folders are the anti-pattern, not a model.

### Every version ships 2 flavours × 2 architectures (mandatory)

For each `x.y.z` the pipeline MUST produce and publish:

- flavours: **root** and **rootless** (uid 1001);
- architectures: **linux/amd64** and **linux/arm64**.

Both architectures are non-negotiable and built natively (amd64 on `ubuntu-latest`, arm64 on `ubuntu-24.04-arm`): no dropping an arch, no QEMU-only shortcut, no publishing a single-arch tag. Both flavours are non-negotiable. Published tags per version — `:<version>`, `:<version>-dev`, `:<version>-rootless`, `:<version>-rootless-dev` — are each multi-arch manifests.

### Build and runtime

- Two targets: `dist` (runtime) and `dev` (`FROM dist` plus Composer, git, rsync, patch).
- Opt-in extensions (`redis`, `memcached`, `xdebug`, `ldap`) ship installed but disabled; the entrypoint enables them from `conf.disabled/` via `*_ENABLE` env vars. Others (`apcu`, `igbinary`, …) are on by default.
- OPcache loading is version-aware: write the `zend_extension=opcache.so` loader only when that shared object exists (newer PHP compiles OPcache in statically). Keep the logic conditional in the Dockerfile; `conf/opcache.ini` holds tuning only.

## Code Style

- **Shell** (entrypoint, `tests/*.sh`, `scripts/*.sh`): POSIX `sh`, ShellCheck-clean — `make shellcheck` (CI enforces via `qa.yml`).
- **Dockerfile**: BuildKit-check clean — `FROM … AS` uppercase, defaults for `ARG`s used in `FROM`, no undefined `ENV` vars. `docker buildx build` prints any checks.
- No formatter configured; match the surrounding style.

## Git Workflow

**Commits** — [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/): `<type>(<scope>): <description>`, lowercase imperative, no trailing period. Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `build`. Every commit carries an `Assisted-by:` trailer (agent/model) via `git commit --trailer` (SparkFabrik policy); reference issues fully qualified (`Refs:` / `Closes: owner/repo#N`).

**Branching** — `feat|fix|chore|ci|test|docs/<kebab-description>`. Never push to `master`; branch and open a PR.

**Rebasing** — rebase onto `master`, no merge commits; `--force-with-lease`, never `--force`.

## Dependencies and Version Pinning

Versions are pinned (no lockfile): PHP extensions/tools and the golang builder in the Dockerfile, plus `COMPOSER_VERSION` in both the `Makefile` and `docker-publish.yml` (keep them in sync).

Before bumping any pin:

1. Never trust training data for "latest" — check the live source.
2. Verify against it:

```bash
# PHP image tags (Docker Hub) — set name= to the line you target
curl -s "https://hub.docker.com/v2/repositories/library/php/tags/?page_size=100&name=<x.y>" | grep -oE '"name":"[^"]*fpm-alpine[0-9.]*"' | sort -u
# PECL release (xdebug/redis/memcached/apcu/igbinary)
curl -s "https://pecl.php.net/rest/r/<ext>/allreleases.xml" | grep -oE '<v>[0-9.]+</v>' | head
# Composer / golang / Blackfire CLI
curl -s https://getcomposer.org/versions | jq '.stable[0]'
curl -s "https://hub.docker.com/v2/repositories/library/golang/tags/?page_size=100&name=alpine" | grep -oE '"name":"[0-9.]+-alpine3\.[0-9]+"' | sort -V | tail
curl -s -A Docker "https://blackfire.io/api/v1/releases" | jq '.cli'
```

3. The shared Dockerfile serves every active version, so a bump must build on all of them, not just the newest. (When PHP 8.5 was added, Xdebug 3.4 and phpredis 6.1 had to be bumped because they do not support 8.5.)
4. Avoid releases published in the last 5 days (supply-chain risk).
5. After a bump, build and test the oldest and newest active versions plus a rootless flavour before opening a PR.

## Testing

`make build-<version>` runs the suite after building: `tests/tests_wrapper.sh` → `tests/image_verify.sh` starts the image and asserts PHP settings, enabled/disabled extensions, FPM config, and the container user.

- Expectations: `tests/expectations/php7/` (`expectations_default`, `expectations_overrides`, `image_env_overrides`) — `php7` is the harness profile name, not a PHP version.
- Test an existing image directly: `./tests/tests_wrapper.sh php7 <image> root` (use the string `unknown uid 1001` as the user argument for rootless).

## CI/CD

GitHub Actions: `qa.yml` (ShellCheck on push/PR) and `docker-publish.yml` (build/test/publish).

| Job       | Runs        | Purpose                                                         |
| --------- | ----------- | --------------------------------------------------------------- |
| `prepare` | PR + master | Emits `PHP_TAGS` as an output (the matrix cannot read `env`).   |
| `test`    | PR + master | Builds each version native amd64 (`--load`) and runs the suite. |
| `build`   | master      | Builds each version per arch natively, pushes by digest.        |
| `merge`   | master      | Assembles the per-arch digests into the multi-arch tags.        |

- `PHP_TAGS` is the only place to add or remove a version; all matrices derive from it. Keep the `make build-<x-y-z>` targets in sync with it.
- `build`/`merge` run only on `master`, so the publish path is first exercised by the merge commit. Watch that run and verify with `docker buildx imagetools inspect <tag>` that each tag is a 2-arch manifest and that root and rootless differ.
- Layer caching uses `type=gha`, scoped per tag/flavour (and per arch in `build`).

## Command Safety

**Safe (autonomous):** `make shellcheck`, `make build-test-image`, `make build-<version>` / `make build-template PHPVER=…` (local, `--load`, no push), `docker buildx build … --load`, `docker buildx imagetools inspect`, `git status|log|diff`, `./scripts/guess_folder.sh <version>`.

**Dangerous (ask first):** bumping any pinned version or `COMPOSER_VERSION`; editing `PHP_TAGS` or the publish workflow; `docker buildx build --push` (publishes); `git push`; opening or merging PRs; `--force-with-lease`, `git commit --amend` on pushed commits.

**Destructive (never):** `git push --force`, force-push to `master`, `git reset --hard`, image/buildx pruning on a shared host, deleting GHCR packages or tags.

## Important Rules

- Build everything in Docker via `make` / `docker buildx`; never install PHP, Composer, or extensions on the host.
- One shared folder per major — express version differences with build args, never fork folders (unless technically impossible, and then document why). Do not touch the frozen `7.x` folders.
- Every published `x.y.z` MUST ship root and rootless, each as a native amd64 + arm64 multi-arch manifest. No dropped arch, no single flavour, no QEMU-only shortcut.
- Discover active versions from `PHP_TAGS` / the Makefile targets; do not assume the current major.
- A shared-Dockerfile bump must build and pass tests on the oldest and newest active versions; verify "latest" against the live registry first.
- Keep `PHP_TAGS`, the `make build-<x-y-z>` targets, and the two `COMPOSER_VERSION` pins in sync.
- Dockerfiles BuildKit-check clean, shell ShellCheck clean.
- Conventional commits with an `Assisted-by:` trailer; branch off `master`, never push to it, rebase with `--force-with-lease`.
