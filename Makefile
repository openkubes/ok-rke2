.PHONY: help install install-server install-agent install-all lint requirements clean

INVENTORY ?= inventory/hosts.yml
PLAYBOOK ?= playbook.yml

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

requirements: ## Install Ansible dependencies
	ansible-galaxy collection install ansible.posix
	ansible-galaxy collection install community.general

install-server: ## Deploy RKE2 server (ok-infra)
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --limit rke2_servers

install-agent: ## Deploy RKE2 agent (ok-gpu)
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --limit rke2_agents

install: ## Deploy full RKE2 cluster (server + agents)
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

lint: ## Lint the Ansible role
	ansible-lint .

check: ## Dry-run the playbook
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --check --diff

ping: ## Test connectivity to all hosts
	ansible -i $(INVENTORY) all -m ping

clean: ## Remove generated files
	find . -name "*.retry" -delete
	find . -name "__pycache__" -delete
