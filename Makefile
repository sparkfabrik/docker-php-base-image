all: build

build:
	docker build -t sparkfabrik/php7.6 7.4.6-fpm-alpine3.10