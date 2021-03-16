MAKEFLAGS += --silent
SHELL := /usr/bin/env bash
ENV_FILE := $(PWD)/.env
DOCKER_COMPOSE := docker-compose
ifneq (,$(wildcard $(ENV_FILE)))
	include $(PWD)/.env
	export
endif

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

env:
	if ! test -f $(ENV_FILE); \
	then \
		>&2 echo "INFO: Creating new env file."; \
		grep -Ev '(^#|^$$)' $(ENV_FILE).example > $(ENV_FILE); \
		>&2 echo "INFO: Done. Open '$(ENV_FILE)' and replace \"change_me\" with real values."; \
	fi

tests: _ensure_test_ssh_key _rebuild_dc_service_on_change
tests:
	docker-compose up -d && \
	$(DOCKER_COMPOSE) run --rm \
		--entrypoint ansible-playbook \
		tests \
		--private-key "/ssh_key" \
		--inventory "test_machine," \
		--extra-vars "azure_tenant_id=$$AZURE_TENANT_ID" \
		--extra-vars "azure_client_id=$$AZURE_CLIENT_ID" \
		--extra-vars "azure_client_secret=$$AZURE_CLIENT_SECRET" \
		tests.yaml; \
	if test "$(TEARDOWN)" == "true"; \
	then \
		$(DOCKER_COMPOSE) down -t 1; \
	fi;

debug:
	$(DOCKER_COMPOSE) run --rm --entrypoint bash test-container;
