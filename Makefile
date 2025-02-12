DOCKER-RUN = docker compose run -e TERM --rm --entrypoint=""
BUNDLE-EXEC = bundle exec

build:
	docker compose build

up:
	docker compose up

down:
	docker compose down

sh:
	$(DOCKER-RUN) web bash

lint:
	$(DOCKER-RUN) web $(BUNDLE-EXEC) rubocop

guard:
	$(DOCKER-RUN) web $(BUNDLE-EXEC) guard

debug:
	$(DOCKER-RUN) web $(BUNDLE-EXEC) rdbg -A web 12345
