build:
	docker compose -f srcs/docker-compose.yml build

up:
	docker compose -f srcs/docker-compose.yml up

upd:
	docker compose -f srcs/docker-compose.yml up -d

down:
	docker compose -f srcs/docker-compose.yml down

vdown:
	docker compose -f srcs/docker-compose.yml down -v

start:
	docker compose -f srcs/docker-compose.yml start

stop:
	docker compose -f srcs/docker-compose.yml stop

check:
	docker compose -f srcs/docker-compose.yml ps

.PHONY: build up upd down vdown start stop