all: build

build:
	docker build -t sparkfabrik/php7.0.33 7.0.33
	docker build -t sparkfabrik/php7.1.29 7.1.29-fpm-alpine3.9
	docker build -t sparkfabrik/php7.2.0 7.2.0-fpm-alpine3.7
	docker build -t sparkfabrik/php7.2.25 7.2.25-fpm-alpine3.10
	docker build -t sparkfabrik/php7.3.24 7.3.24-fpm-alpine3.12
	docker build -t sparkfabrik/php7.4.6 7.4.6-fpm-alpine3.10
