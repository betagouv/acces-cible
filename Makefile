DOCKER-RUN = docker compose run -e TERM --rm --entrypoint=""
BUNDLE-EXEC = bundle exec

DATABASE_URL = postgresql://postgres:dummy@db:5433

.PHONY: db

build:
	docker compose build

up:
	docker compose up

down:
	docker compose down

die:
	docker compose down --remove-orphans --volumes

sh:
	$(DOCKER-RUN) web bash

cl:
	$(DOCKER-RUN) web ./bin/rails c

lint:
	$(DOCKER-RUN) web $(BUNDLE-EXEC) rubocop

guard:
	$(DOCKER-RUN) web $(BUNDLE-EXEC) guard

debug:
	$(DOCKER-RUN) web $(BUNDLE-EXEC) rdbg -nA web 12345

db:
	$(DOCKER-RUN) -e PAGER= db psql $(DATABASE_URL)
