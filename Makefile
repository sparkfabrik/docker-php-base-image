build-5-4-45:
	docker buildx build --load -t sparkfabrik/php5.4.45 5.4.45

build-5-5-9:
	docker buildx build --load -t sparkfabrik/php5.5.9 5.5.9

build-5-6-19:
	docker buildx build --load -t sparkfabrik/php5.6.19 5.6.19

build-5-6-26:
	docker buildx build --load -t sparkfabrik/php5.6.26 5.6.26

build-7-0-6:
	docker buildx build --load -t sparkfabrik/php7.0.6 7.0.6

build-7-0-8:
	docker buildx build --load -t sparkfabrik/php7.0.6 7.0.8

build-7-0-20:
	docker buildx build --load -t sparkfabrik/php7.0.20 7.0.20

build-7-0-33:
	docker buildx build --load -t sparkfabrik/php7.0.33 7.0.33

build-7-1-6:
	docker buildx build --load -t sparkfabrik/php7.1.6 7.1.6

build-7-1-11: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.11-fpm-alpine3.4 7.1.11-fpm-alpine3.4
	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.11-fpm-alpine3.4 root

build-7-1-11-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.11-fpm-alpine3.4-rootless --build-arg user=1001 7.1.11-fpm-alpine3.4
	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.11-fpm-alpine3.4-rootless "unknown uid 1001"

build-7-1-12: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.12-fpm-alpine3.4 7.1.12-fpm-alpine3.4
	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.12-fpm-alpine3.4 root

build-7-1-12-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.12-fpm-alpine3.4-rootless --build-arg user=1001 7.1.12-fpm-alpine3.4
	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.12-fpm-alpine3.4-rootless "unknown uid 1001"

build-7-1-22: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.22-fpm-alpine3.8 7.1.22-fpm-alpine3.8
	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.22-fpm-alpine3.8 root

build-7-1-22-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.22-fpm-alpine3.8-rootless --build-arg user=1001 7.1.22-fpm-alpine3.8
	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.22-fpm-alpine3.8-rootless "unknown uid 1001"

build-7-1-29: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.29-fpm-alpine3.9 7.1.29-fpm-alpine3.9
	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.29-fpm-alpine3.9 root

build-7-1-29-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.1.29-fpm-alpine3.9-rootless --build-arg user=1001 7.1.29-fpm-alpine3.9
	./tests/tests_wrapper.sh php7/mailhog_enabled sparkfabrik/docker-php-base-image:7.1.29-fpm-alpine3.9-rootless "unknown uid 1001"

build-7-2-0: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.2.0-fpm-alpine3.7 7.2.0-fpm-alpine3.7
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.2.0-fpm-alpine3.7 root

build-7-2-0-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.2.0-fpm-alpine3.7-rootless --build-arg user=1001 7.2.0-fpm-alpine3.7
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.2.0-fpm-alpine3.7-rootless "unknown uid 1001"

build-7-2-25: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.2.25-fpm-alpine3.10 7.2.25-fpm-alpine3.10
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.2.25-fpm-alpine3.10 root

build-7-2-25-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.2.25-fpm-alpine3.10-rootless --build-arg user=1001 7.2.25-fpm-alpine3.10
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.2.25-fpm-alpine3.10-rootless "unknown uid 1001"

build-7-3-24: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.3.24-fpm-alpine3.12 7.3.24-fpm-alpine3.12
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.3.24-fpm-alpine3.12 root

build-7-3-24-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.3.24-fpm-alpine3.12-rootless --build-arg user=1001 7.3.24-fpm-alpine3.12
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.3.24-fpm-alpine3.12-rootless "unknown uid 1001"

build-7-4-6: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.6-fpm-alpine3.10 7.4.6-fpm-alpine3.10
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.6-fpm-alpine3.10 root

build-7-4-6-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.6-fpm-alpine3.10-rootless --build-arg user=1001 7.4.6-fpm-alpine3.10
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.6-fpm-alpine3.10-rootless "unknown uid 1001"

build-7-4-16: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.16-fpm-alpine3.13 7.4.16-fpm-alpine3.13
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.16-fpm-alpine3.13 root

build-7-4-16-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.16-fpm-alpine3.13-rootless --build-arg user=1001 7.4.16-fpm-alpine3.13
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.16-fpm-alpine3.13-rootless "unknown uid 1001"

build-7-4-20: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.20-fpm-alpine3.13 7.4.20-fpm-alpine3.13
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.20-fpm-alpine3.13 root

build-7-4-20-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.20-fpm-alpine3.13-rootless --build-arg user=1001 7.4.20-fpm-alpine3.13
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.20-fpm-alpine3.13-rootless "unknown uid 1001"

build-7-4-26: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.26-fpm-alpine3.15 7.4.26-fpm-alpine3.15
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.26-fpm-alpine3.15 root

build-7-4-26-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:7.4.26-fpm-alpine3.15-rootless --build-arg user=1001 7.4.26-fpm-alpine3.15
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:7.4.26-fpm-alpine3.15-rootless "unknown uid 1001"

build-8-0-8: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:8.0.8-fpm-alpine3.13 8.0.8-fpm-alpine3.13
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:8.0.8-fpm-alpine3.13 root

build-8-0-8-rootless: build-test-image
	docker buildx build --load -t sparkfabrik/docker-php-base-image:8.0.8-fpm-alpine3.13-rootless --build-arg user=1001 8.0.8-fpm-alpine3.13
	./tests/tests_wrapper.sh php7 sparkfabrik/docker-php-base-image:8.0.8-fpm-alpine3.13-rootless "unknown uid 1001"

build-test-image:
	docker buildx build --load -t sparkfabrik/php-test-image:latest tests
