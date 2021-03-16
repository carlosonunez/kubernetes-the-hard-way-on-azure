MAKEFLAGS += --silent
SHELL := /usr/bin/env bash
DOCKER_COMPOSE := docker-compose

_ensure_test_ssh_key:
	if ! test -f "id_rsa" || ! test -f "id_rsa.pub"; \
	then \
		>&2 echo "INFO: Generating SSH keys for test machine. \
These will not be committed to your Git history."; \
		ssh-keygen -t rsa -f id_rsa -q -N '' && \
			cat ./id_rsa.pub >> ./authorized_keys; \
	fi

_rebuild_dc_service_on_change:
	for changed_service in $$(git status --porcelain | \
		grep ".Dockerfile" | \
		cut -f3 -d ' ' | \
		sed 's/.Dockerfile//'); \
	do \
		>&2 echo "INFO: Rebuilding '$$changed_service'; commit this file to stop this."; \
		$(DOCKER_COMPOSE) build -q $$changed_service; \
	done

tests: _ensure_test_ssh_key _rebuild_dc_service_on_change
tests:
	docker-compose up -d && \
	$(DOCKER_COMPOSE) run --rm \
		--entrypoint ansible-playbook \
		tests \
		--private-key "/ssh_key" \
		--inventory "test_machine," \
		tests.yaml; \
	$(DOCKER_COMPOSE) down -t 1;

debug:
	$(DOCKER_COMPOSE) run --rm --entrypoint bash test-container;
