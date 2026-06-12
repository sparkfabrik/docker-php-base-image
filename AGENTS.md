# AGENTS.md

## Project Overview

This repository builds and publishes the SparkFabrik PHP-FPM base Docker images. Each image bundles a pinned PHP version (FPM, Alpine) with a fixed set of extensions, Composer, MailHog, and the Blackfire client/probe, plus an entrypoint that turns environment variables into PHP/FPM configuration at container start. Images are published to `ghcr.io/sparkfabrik/docker-php-base-image`.

The active images are the PHP 8.x line, all built from a single shared folder (`8/`). The numbered `7.x` folders (`7.3.24-fpm-alpine3.12`, `7.4*`, etc.) are frozen legacy builds kept for reference; do not extend them.

**Tech stack:** Dockerfiles (multi-stage, `dist` and `dev` targets), POSIX shell (entrypoint, test harness), GNU Make as the task runner, GitHub Actions for CI/publishing. There is no application package manager at the repository root; "dependencies" are upstream versions pinned inside `8/Dockerfile` and the `Makefile`.

### Layout

- `8/` — the shared source for every PHP 8.x image. `Dockerfile`, `docker-entrypoint.sh`, `conf/` (active php.ini fragments), `conf.disabled/` (opt-in extensions enabled by the entrypoint), `fpm-conf-templates/`.
- `scripts/guess_folder.sh` — maps a PHP version (e.g. `8.5.7-fpm-alpine3.24`) to its build folder, falling back from full version to `major.minor` to `major` (so all `8.x` resolve to `8/`).
- `tests/` — image end-to-end verification (`image_verify.sh`, `tests_wrapper.sh`, `expectations/`).
- `shellcheck/` — dockerized ShellCheck setup used by `make shellcheck`.
- `Makefile` — build targets per version and the generic build templates.
- `.github/workflows/` — `docker-publish.yml` (test + native multi-arch publish), `qa.yml` (ShellCheck).

## Setup

Everything runs in Docker via `make` and `docker buildx`. No local PHP, Composer, or PHP extensions are required — they exist only inside the built images.

Requirements on the host: Docker with Buildx, and GNU Make.

```bash
# Build and locally test a specific image (builds dist + dev, then runs the test suite)
make build-8-5-7

# Same for the rootless flavour (runs as uid 1001)
make build-8-5-7-rootless

# Build any version generically (this is what CI uses)
make build-template PHPVER=8.5.7-fpm-alpine3.24
make build-rootless-template PHPVER=8.5.7-fpm-alpine3.24
```

`make build-<version>` targets are convenience wrappers for local use; they set `PHPVER` and delegate to `build-template` / `build-rootless-template`.

## Key Conventions

- **One shared folder for all 8.x.** Edit `8/` to change behaviour for every PHP 8 image. Per-version differences are handled at build time (build args, conditional shell), not by forking the folder. The recently consolidated layout must stay this way.
- **Version resolution is automatic.** `scripts/guess_folder.sh` picks the folder from `PHPVER`. A new `8.x` version needs no new folder.
- **Two build targets per image:** `dist` (runtime image) and `dev` (adds Composer, git, rsync, patch — built `FROM dist`). Published tags: `:<version>`, `:<version>-dev`, and the `-rootless` variants.
- **Opt-in extensions.** `redis`, `memcached`, `xdebug`, `ldap` ship installed but disabled; the entrypoint enables them from `conf.disabled/` based on `*_ENABLE` env vars. `apcu`, `igbinary`, and the rest are on by default.
- **OPcache loading is version-aware.** PHP ≤ 8.4 loads `opcache.so`; PHP 8.5 has OPcache compiled in statically. `8/Dockerfile` only writes the `zend_extension=opcache.so` loader when the shared object exists. `8/conf/opcache.ini` carries the tuning only.
- **Pinned upstream versions live in two places:** extension/tool versions in `8/Dockerfile` (`XDEBUG_VERSION`, `PHPREDIS_VERSION`, `MEMCACHE_VERSION`, `APCU_VERSION`, `BLACKFIRE_CLIENT_VERSION`, golang builder, MailHog) and `COMPOSER_VERSION` in both the `Makefile` and `docker-publish.yml`. Keep the two Composer pins in sync.
- `docker-compose.yml.dist` is a legacy usage example, not part of the build.

## Code Style

- **Shell** (entrypoint, `tests/*.sh`, `scripts/*.sh`): POSIX `sh`, must pass ShellCheck. Run `make shellcheck` (runs ShellCheck in a container over the repo). CI enforces this via `qa.yml`.
- **Dockerfile**: keep it BuildKit-check clean. Use `FROM … AS` (uppercase), give `ARG`s used in `FROM` a default, and do not reference undefined variables in `ENV`. Verify locally with `docker buildx build` (it prints any checks) or `docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint` for workflow files.
- No EditorConfig or language formatter is configured; match the surrounding style.

## Git Workflow

### Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<scope>): <description>
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`, `perf`, `build`. **Scope** is optional — use the affected component (e.g. `php8`, `ci`). Keep the description lowercase, imperative, no trailing period.

Every commit must carry an `Assisted-by:` trailer identifying the agent and model (SparkFabrik policy), applied via `git commit --trailer`. Reference the related issue with a fully qualified path when one exists (`Refs:`/`Closes: owner/repo#N`).

### Branching

- Branch naming: `feat/`, `fix/`, `chore/`, `ci/`, `test/`, `docs/` prefix + kebab-case description (e.g. `ci/arm64-native-deploy`, `fix/deploy-flavour-digest-collision`).
- **Never push directly to `master`.** Always create a feature branch and open a pull request.

### Rebasing

- Rebase onto `master` before pushing; avoid merge commits.
- Use `--force-with-lease` (never `--force`) after rebasing or amending.

## Dependencies and Version Pinning

This repo pins upstream versions rather than resolving them from a lockfile. The pins live in `8/Dockerfile` (PHP extensions via PECL, the golang builder image, MailHog, the Blackfire client) and in the `COMPOSER_VERSION` variables.

Before bumping any pin:

1. **Never assume you know the latest version.** Training data is stale — always verify against the live source.
2. **Check the live source:**

```bash
# Official PHP image tags (Docker Hub)
curl -s "https://hub.docker.com/v2/repositories/library/php/tags/?page_size=100&name=8.5" \
  | grep -oE '"name":"[^"]*fpm-alpine[0-9.]*"' | sort -u

# PECL extension releases (xdebug, redis, memcached, apcu, igbinary)
curl -s "https://pecl.php.net/rest/r/xdebug/allreleases.xml" | grep -oE '<v>[0-9.]+</v>' | head

# Composer
curl -s https://getcomposer.org/versions | jq '.stable[0]'

# golang image tags (Docker Hub), Blackfire CLI
curl -s "https://hub.docker.com/v2/repositories/library/golang/tags/?page_size=100&name=alpine" | grep -oE '"name":"1\.[0-9]+-alpine3\.[0-9]+"' | sort -V | tail
curl -s -A Docker "https://blackfire.io/api/v1/releases" | jq '.cli'
```

3. **Verify compatibility with the target PHP versions**, not just "latest". The `8/Dockerfile` is shared across PHP 8.3–8.5, so a bump must build on every active version. Example: Xdebug 3.4 does not support PHP 8.5, and phpredis 6.1 fails to compile against PHP 8.5 headers — both required bumps when 8.5 was added.
4. **Avoid releases published within the last 5 days** to reduce supply-chain risk.
5. **After any bump, build and test the oldest and newest active versions** (`make build-8-3-2` and `make build-8-5-7`, plus a rootless flavour) before opening a PR.

## Testing

`make build-<version>` automatically runs the end-to-end suite after building, via `tests/tests_wrapper.sh` → `tests/image_verify.sh`. The harness starts the built image and asserts expected PHP settings, enabled/disabled extensions, FPM config, and the container user.

- Expectations live in `tests/expectations/php7/` (`expectations_default`, `expectations_overrides`, `image_env_overrides`) — the folder name is the harness profile, not a PHP version.
- The test image itself is built by `make build-test-image` (target `tests/Dockerfile`).
- To test an already-built image directly: `./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:<version> root` (use the expected uid string, e.g. `unknown uid 1001`, for rootless).

## CI/CD

GitHub Actions, two workflows:

- **`qa.yml`** — runs ShellCheck on every push and pull request.
- **`docker-publish.yml`** — the build/test/publish pipeline.

### docker-publish.yml jobs

| Job       | Runs on     | Purpose                                                                                                                               |
| --------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `prepare` | PR + master | Surfaces the `PHP_TAGS` version list as an output (the `env` context is not available to `strategy.matrix`, so it is forwarded here). |
| `test`    | PR + master | Builds each version single-arch (native amd64, `--load`, no QEMU) and runs the test suite.                                            |
| `build`   | master only | Builds each version per architecture natively (amd64 on `ubuntu-latest`, arm64 on `ubuntu-24.04-arm`) and pushes by digest.           |
| `merge`   | master only | Assembles the per-arch digests into the final multi-arch tags with `docker buildx imagetools create`.                                 |

Key points:

- **`PHP_TAGS` (workflow `env`) is the single source of truth** for which versions are built. Add or remove a version there; `test`, `build`, and `merge` all derive their matrix from it. Each entry has `short` (Makefile target suffix) and `full` (the PHPVER tag).
- The numbered `make build-<version>` targets must stay in sync with `PHP_TAGS` so local builds match CI.
- Layer caching uses `type=gha`, scoped per tag/flavour (and per arch in `build`).
- `build`/`merge` only run on `master`, so the publish path is first exercised by the merge commit, not by the PR. Watch the first post-merge run and spot-check tags with `docker buildx imagetools inspect`.

## Command Safety

### Safe (run autonomously)

Read-only or local, non-publishing:

- `make shellcheck`, `make build-test-image`
- `make build-<version>` / `make build-template PHPVER=…` (builds and tests locally with `--load`; does not push)
- `docker buildx build … --load`, `docker buildx imagetools inspect`
- `git status`, `git log`, `git diff`, `./scripts/guess_folder.sh <version>`

### Dangerous (ask the user first)

State-changing or outward-facing:

- Bumping any pinned version in `8/Dockerfile` or `COMPOSER_VERSION`
- Editing `PHP_TAGS` or the publish workflow
- `docker buildx build --push …` (publishes to GHCR)
- `git push`, opening/merging PRs
- `git push --force-with-lease`, `git commit --amend` on already-pushed commits

### Destructive (never run)

- `git push --force` to any branch, force-push to `master`
- `git reset --hard`, `docker buildx prune -a` / image pruning on a shared host
- Deleting GHCR packages or published tags

## Important Rules

- Never install PHP, Composer, or extensions on the host — everything lives inside the images, built via `make` / `docker buildx`.
- Edit the shared `8/` folder for all PHP 8.x changes; do not fork per version and do not touch the frozen `7.x` folders.
- The `8/Dockerfile` is shared across PHP 8.3–8.5 — any extension or tool bump must build and pass tests on every active version, oldest and newest.
- Always verify the latest version against the live registry before bumping a pin; never trust training data.
- Keep `PHP_TAGS` (CI) and the `make build-<version>` targets and the two `COMPOSER_VERSION` pins in sync.
- Keep Dockerfiles BuildKit-check clean and shell scripts ShellCheck clean (`make shellcheck`).
- Conventional commits with an `Assisted-by:` trailer; branch off `master`, never push to it directly, rebase with `--force-with-lease`.
