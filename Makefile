.PHONY: shellcheck

COMPOSER_VERSION = 2.8.9

# build-7-1-11: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.11-fpm-alpine3.4 7.1.11-fpm-alpine3.4
# 	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.11-fpm-alpine3.4 root
#
# build-7-1-11-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.11-fpm-alpine3.4-rootless --build-arg user=1001 7.1.11-fpm-alpine3.4
# 	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.11-fpm-alpine3.4-rootless "unknown uid 1001"
#
# build-7-1-12: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.12-fpm-alpine3.4 7.1.12-fpm-alpine3.4
# 	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.12-fpm-alpine3.4 root
#
# build-7-1-12-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.12-fpm-alpine3.4-rootless --build-arg user=1001 7.1.12-fpm-alpine3.4
# 	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.12-fpm-alpine3.4-rootless "unknown uid 1001"
#
# build-7-1-22: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.22-fpm-alpine3.8 7.1.22-fpm-alpine3.8
# 	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.22-fpm-alpine3.8 root
#
# build-7-1-22-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.22-fpm-alpine3.8-rootless --build-arg user=1001 7.1.22-fpm-alpine3.8
# 	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.22-fpm-alpine3.8-rootless "unknown uid 1001"
#
# build-7-1-29: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.29-fpm-alpine3.9 7.1.29-fpm-alpine3.9
# 	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.29-fpm-alpine3.9 root
#
# build-7-1-29-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.29-fpm-alpine3.9-rootless --build-arg user=1001 7.1.29-fpm-alpine3.9
# 	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.29-fpm-alpine3.9-rootless "unknown uid 1001"
#
# build-7-2-0: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.2.0-fpm-alpine3.7 7.2.0-fpm-alpine3.7
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.2.0-fpm-alpine3.7 root
#
# build-7-2-0-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.2.0-fpm-alpine3.7-rootless --build-arg user=1001 7.2.0-fpm-alpine3.7
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.2.0-fpm-alpine3.7-rootless "unknown uid 1001"
#
# build-7-2-25: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.2.25-fpm-alpine3.10 7.2.25-fpm-alpine3.10
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.2.25-fpm-alpine3.10 root
#
# build-7-2-25-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.2.25-fpm-alpine3.10-rootless --build-arg user=1001 7.2.25-fpm-alpine3.10
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.2.25-fpm-alpine3.10-rootless "unknown uid 1001"
#
# build-7-3-24: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.3.24-fpm-alpine3.12 7.3.24-fpm-alpine3.12
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.3.24-fpm-alpine3.12 root
#
# build-7-3-24-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.3.24-fpm-alpine3.12-rootless --build-arg user=1001 7.3.24-fpm-alpine3.12
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.3.24-fpm-alpine3.12-rootless "unknown uid 1001"
#
# build-7-4-6: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.6-fpm-alpine3.10 7.4.6-fpm-alpine3.10
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.6-fpm-alpine3.10 root
#
# build-7-4-6-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.6-fpm-alpine3.10-rootless --build-arg user=1001 7.4.6-fpm-alpine3.10
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.6-fpm-alpine3.10-rootless "unknown uid 1001"
#
# build-7-4-16: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.16-fpm-alpine3.13 7.4.16-fpm-alpine3.13
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.16-fpm-alpine3.13 root
#
# build-7-4-16-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.16-fpm-alpine3.13-rootless --build-arg user=1001 7.4.16-fpm-alpine3.13
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.16-fpm-alpine3.13-rootless "unknown uid 1001"
#
# build-7-4-20: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.20-fpm-alpine3.13 7.4.20-fpm-alpine3.13
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.20-fpm-alpine3.13 root
#
# build-7-4-20-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.20-fpm-alpine3.13-rootless --build-arg user=1001 7.4.20-fpm-alpine3.13
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.20-fpm-alpine3.13-rootless "unknown uid 1001"
#
# build-7-4-26: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.26-fpm-alpine3.15 7.4.26-fpm-alpine3.15
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.26-fpm-alpine3.15 root
#
# build-7-4-26-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.26-fpm-alpine3.15-rootless --build-arg user=1001 7.4.26-fpm-alpine3.15
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.26-fpm-alpine3.15-rootless "unknown uid 1001"
#
# build-7-4-29: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.29-fpm-alpine3.15 7.4.29-fpm-alpine3.15
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.29-fpm-alpine3.15 root
#
# build-7-4-29-rootless: build-test-image
# 	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.29-fpm-alpine3.15-rootless --build-arg user=1001 7.4.29-fpm-alpine3.15
# 	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.29-fpm-alpine3.15-rootless "unknown uid 1001"
#
# build-7-4-30: PHPVER=7.4.30-fpm-alpine3.16
# build-7-4-30: build-template
#
# build-7-4-30-rootless: PHPVER=7.4.30-fpm-alpine3.16
# build-7-4-30-rootless: build-rootless-template
#
# build-7-4-32: PHPVER=7.4.32-fpm-alpine3.16
# build-7-4-32: build-template
#
# build-7-4-32-rootless: PHPVER=7.4.32-fpm-alpine3.16
# build-7-4-32-rootless: build-rootless-template
#
# build-7-4-33: PHPVER=7.4.33-fpm-alpine3.16
# build-7-4-33: build-template
#
# build-7-4-33-rootless: PHPVER=7.4.33-fpm-alpine3.16
# build-7-4-33-rootless: build-rootless-template
#
# build-8-0-8: PHPVER=8.0.8-fpm-alpine3.13
# build-8-0-8: build-template
#
# build-8-0-8-rootless: PHPVER=8.0.8-fpm-alpine3.13
# build-8-0-8-rootless: build-rootless-template
#
# build-8-1-5: PHPVER=8.1.5-fpm-alpine3.15
# build-8-1-5: build-template
#
# build-8-1-5-rootless: PHPVER=8.1.5-fpm-alpine3.15
# build-8-1-5-rootless: build-rootless-template
#
# build-8-1-12: PHPVER=8.1.12-fpm-alpine3.16
# build-8-1-12: build-template
#
# build-8-1-12-rootless: PHPVER=8.1.12-fpm-alpine3.16
# build-8-1-12-rootless: build-rootless-template

build-8-1-10: PHPVER=8.1.10-fpm-alpine3.16
build-8-1-10: build-template

build-8-1-10-rootless: PHPVER=8.1.10-fpm-alpine3.16
build-8-1-10-rootless: build-rootless-template

build-8-1-16: PHPVER=8.1.16-fpm-alpine3.16
build-8-1-16: build-template

build-8-1-16-rootless: PHPVER=8.1.16-fpm-alpine3.16
build-8-1-16-rootless: build-rootless-template

build-8-2-3: PHPVER=8.2.3-fpm-alpine3.16
build-8-2-3: build-template

build-8-2-3-rootless: PHPVER=8.2.3-fpm-alpine3.16
build-8-2-3-rootless: build-rootless-template

build-8-3-2: PHPVER=8.3.2-fpm-alpine3.18
build-8-3-2: build-template

build-8-3-2-rootless: PHPVER=8.3.2-fpm-alpine3.18
build-8-3-2-rootless: build-rootless-template

build-8-3-15: PHPVER=8.3.15-fpm-alpine3.21
build-8-3-15: build-template

build-8-3-15-rootless: PHPVER=8.3.15-fpm-alpine3.21
build-8-3-15-rootless: build-rootless-template

build-8-4-2: PHPVER=8.4.2-fpm-alpine3.21
build-8-4-2: build-template

build-8-4-2-rootless: PHPVER=8.4.2-fpm-alpine3.21
build-8-4-2-rootless: build-rootless-template

build-template: guessing-folder build-test-image
	docker buildx build \
		--load \
		--build-arg PHPVER=$(PHPVER) \
		--target dist \
		-t sparkfabrik/docker-php-base-image:$(PHPVER) \
		--progress=$${DOCKER_BUILD_PROGRESS:-auto} \
		$(shell ./scripts/guess_folder.sh "$(PHPVER)")
	docker buildx build \
		--load \
		--build-arg PHPVER=$(PHPVER) \
		--build-arg COMPOSER_VERSION="$(COMPOSER_VERSION)" \
		--target dev \
		-t sparkfabrik/docker-php-base-image:$(PHPVER)-dev \
		--progress=$${DOCKER_BUILD_PROGRESS:-auto} \
		$(shell ./scripts/guess_folder.sh "$(PHPVER)")
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:$(PHPVER) root

build-rootless-template: guessing-folder build-test-image
	docker buildx build \
		--load \
		--build-arg PHPVER=$(PHPVER) \
		--build-arg user=1001 \
		--target dist \
		-t sparkfabrik/docker-php-base-image:$(PHPVER)-rootless \
		--progress=$${DOCKER_BUILD_PROGRESS:-auto} \
		$(shell ./scripts/guess_folder.sh "$(PHPVER)")
	docker buildx build \
		--load \
		--build-arg PHPVER=$(PHPVER) \
		--build-arg user=1001 \
		--build-arg COMPOSER_VERSION="$(COMPOSER_VERSION)" \
		--target dev \
		-t sparkfabrik/docker-php-base-image:$(PHPVER)-rootless-dev \
		--progress=$${DOCKER_BUILD_PROGRESS:-auto} \
		$(shell ./scripts/guess_folder.sh "$(PHPVER)")
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:$(PHPVER)-rootless "unknown uid 1001"

guessing-folder:
	@echo "The folder used to build the docker image is: $(shell ./scripts/guess_folder.sh "$(PHPVER)")"

build-test-image:
	docker buildx build --load -t sparkfabrik/php-test-image:latest tests

shellcheck-build:
	@docker build -f shellcheck/Dockerfile -t sparkfabrik/shellchek shellcheck

shellcheck: shellcheck-build
	@docker run --rm -it -w /app -v $${PWD}:/app sparkfabrik/shellchek
