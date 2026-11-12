SHELL := /bin/sh
.DEFAULT_GOAL := help

COMPOSE ?= docker compose

# Keep setup, database preparation, and service changes in order under make -j.
.NOTPARALLEL:
.PHONY: help env check-docker db-up setup run up build stop down restart logs status \
	db-prepare db-migrate db-seed test check console shell

help: ## Show the available local development commands.
	@awk 'BEGIN {FS = ":.*## "; printf "\nBoda local development\n\n"} /^[a-zA-Z_-]+:.*## / {printf "  make %-14s %s\n", $$1, $$2} END {printf "\nFirst run: make setup\n\n"}' $(MAKEFILE_LIST)

env: ## Create .env from .env.example if it does not exist.
	@if [ ! -e .env ] && [ ! -L .env ]; then \
		cp .env.example .env && \
		printf '%s\n' 'Created .env from .env.example.'; \
	fi

check-docker:
	@command -v docker >/dev/null 2>&1 || { printf '%s\n' 'Docker is required. Install Docker Desktop and try again.' >&2; exit 1; }
	@$(COMPOSE) version >/dev/null 2>&1 || { printf '%s\n' 'Docker Compose v2 is required (docker compose).' >&2; exit 1; }
	@docker info >/dev/null 2>&1 || { printf '%s\n' 'Docker is not running or is not accessible. Start Docker Desktop and try again.' >&2; exit 1; }

setup: env check-docker ## First run: build and start the app, prepare the database, and load seeds.
	$(COMPOSE) up --build --detach --wait
	@$(COMPOSE) exec -T web bin/rails runner script/local_urls.rb

up: env check-docker ## Start the app and database; wait until both are healthy.
	$(COMPOSE) up --detach --wait
	@$(COMPOSE) exec -T web bin/rails runner script/local_urls.rb

run: up ## Start the project locally (alias for make up).

build: env check-docker ## Build the Rails image after gem or Dockerfile changes.
	$(COMPOSE) build web

stop: check-docker ## Stop services while keeping their containers and data.
	$(COMPOSE) stop

down: check-docker ## Remove service containers; keep the database and uploaded photos.
	$(COMPOSE) down

restart: check-docker ## Restart the Rails web service.
	$(COMPOSE) restart web

logs: check-docker ## Follow the Rails logs (Ctrl-C exits the log view).
	$(COMPOSE) logs --follow --tail=100 web

status: check-docker ## Show service status and health.
	$(COMPOSE) ps

db-up: env check-docker
	$(COMPOSE) up --detach --wait db

db-prepare: db-up ## Create the development database if needed and apply pending migrations.
	$(COMPOSE) run --rm --no-deps --build web bin/rails db:prepare

db-migrate: db-up ## Apply pending development database migrations.
	$(COMPOSE) run --rm --no-deps --build web bin/rails db:migrate

db-seed: db-up ## Load the planner account and optional sample weddings safely again.
	$(COMPOSE) run --rm --no-deps --build web bin/rails db:seed

test: db-up ## Prepare the separate test database and run Rails tests.
	$(COMPOSE) run --rm --no-deps --build -T -e RAILS_ENV=test web bin/rails db:prepare
	$(COMPOSE) run --rm --no-deps -T -e RAILS_ENV=test web bin/rails test

check: db-up ## Run all project checks: test database, autoloading, and tests.
	$(COMPOSE) run --rm --no-deps --build -T web bin/ci

console: db-up ## Open an interactive Rails console.
	$(COMPOSE) run --rm --no-deps --build web bin/rails console

shell: db-up ## Open an interactive shell in the Rails container.
	$(COMPOSE) run --rm --no-deps --build web /bin/sh


migrate: db-up ## Apply pending development database migrations.
	$(COMPOSE) run --rm --no-deps --build web bin/rails db:migrate