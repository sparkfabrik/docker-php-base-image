build-5-4-45:
	docker build -t sparkfabrik/php5.4.45 5.4.45

build-5-5-9:
	docker build -t sparkfabrik/php5.5.9 5.5.9

build-5-6-19:
	docker build -t sparkfabrik/php5.6.19 5.6.19

build-5-6-26:
	docker build -t sparkfabrik/php5.6.26 5.6.26

build-7-0-6:
	docker build -t sparkfabrik/php7.0.6 7.0.6

build-7-0-8:
	docker build -t sparkfabrik/php7.0.6 7.0.8

build-7-0-20:
	docker build -t sparkfabrik/php7.0.20 7.0.20

build-7-0-33:
	docker build -t sparkfabrik/php7.0.33 7.0.33

build-7-1-6:
	docker build -t sparkfabrik/php7.1.6 7.1.6

build-7-1-11: build-test-image
	docker build -t sparkfabrik/php-base-image:7.1.11-fpm-alpine3.4 7.1.11-fpm-alpine3.4
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/mailhog_enabled/expectations_default \
		sparkfabrik/php-base-image:7.1.11-fpm-alpine3.4
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/mailhog_enabled/expectations_overrides \
			--env-file ./tests/expectations/php7/mailhog_enabled/image_env_overrides \
		sparkfabrik/php-base-image:7.1.11-fpm-alpine3.4

build-7-1-12: build-test-image
	docker build -t sparkfabrik/php-base-image:7.1.12-fpm-alpine3.4 7.1.12-fpm-alpine3.4
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/mailhog_enabled/expectations_default \
		sparkfabrik/php-base-image:7.1.12-fpm-alpine3.4
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/mailhog_enabled/expectations_overrides \
			--env-file ./tests/expectations/php7/mailhog_enabled/image_env_overrides \
		sparkfabrik/php-base-image:7.1.12-fpm-alpine3.4

build-7-1-22: build-test-image
	docker build -t sparkfabrik/php-base-image:7.1.22-fpm-alpine3.8 7.1.22-fpm-alpine3.8
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/mailhog_enabled/expectations_default \
		sparkfabrik/php-base-image:7.1.22-fpm-alpine3.8
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/mailhog_enabled/expectations_overrides \
			--env-file ./tests/expectations/php7/mailhog_enabled/image_env_overrides \
		sparkfabrik/php-base-image:7.1.22-fpm-alpine3.8

build-7-1-29: build-test-image
	docker build -t sparkfabrik/php-base-image:7.1.29-fpm-alpine3.9 7.1.29-fpm-alpine3.9
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/mailhog_enabled/expectations_default \
		sparkfabrik/php-base-image:7.1.29-fpm-alpine3.9
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/mailhog_enabled/expectations_overrides \
			--env-file ./tests/expectations/php7/mailhog_enabled/image_env_overrides \
		sparkfabrik/php-base-image:7.1.29-fpm-alpine3.9

build-7-2-0: build-test-image
	docker build -t sparkfabrik/php-base-image:7.2.0-fpm-alpine3.7 7.2.0-fpm-alpine3.7
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/expectations_default \
		sparkfabrik/php-base-image:7.2.0-fpm-alpine3.7
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/expectations_overrides \
			--env-file ./tests/expectations/php7/image_env_overrides \
		sparkfabrik/php-base-image:7.2.0-fpm-alpine3.7

build-7.2.25: build-test-image
	docker build -t sparkfabrik/php-base-image:7.2.25-fpm-alpine3.10 7.2.25-fpm-alpine3.10
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/expectations_default \
		sparkfabrik/php-base-image:7.2.25-fpm-alpine3.10
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/expectations_overrides \
			--env-file ./tests/expectations/php7/image_env_overrides \
		sparkfabrik/php-base-image:7.2.25-fpm-alpine3.10

build-7-3-24: build-test-image
	docker build -t sparkfabrik/php-base-image:7.3.24-fpm-alpine3.12 7.3.24-fpm-alpine3.12
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/expectations_default \
		sparkfabrik/php-base-image:7.3.24-fpm-alpine3.12
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/expectations_overrides \
			--env-file ./tests/expectations/php7/image_env_overrides \
		sparkfabrik/php-base-image:7.3.24-fpm-alpine3.12

build-7-4-6: build-test-image
	docker build -t sparkfabrik/php-base-image:7.4.6-fpm-alpine3.10 7.4.6-fpm-alpine3.10
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/expectations_default \
		sparkfabrik/php-base-image:7.4.6-fpm-alpine3.10
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/expectations_overrides \
			--env-file ./tests/expectations/php7/image_env_overrides \
		sparkfabrik/php-base-image:7.4.6-fpm-alpine3.10

build-7-4-16-rootless: build-test-image
	docker build -t sparkfabrik/php-base-image:7.4.16-fpm-alpine3.13-rootless 7.4.16-fpm-alpine3.13-rootless
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/expectations_default \
		sparkfabrik/php-base-image:7.4.16-fpm-alpine3.13-rootless
	./tests/image_verify.sh \
			--source ./tests/expectations/php7/expectations_overrides \
			--env-file ./tests/expectations/php7/image_env_overrides \
		sparkfabrik/php-base-image:7.4.16-fpm-alpine3.13-rootless

build-test-image:
	docker build -t sparkfabrik/php-test-image:latest tests
