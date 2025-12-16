# Makefile for Cloudflare Operator Helm Chart

CHART_DIR := .
SCRIPTS_DIR := $(CHART_DIR)/scripts
DIST_DIR := ../../dist

.PHONY: help lint test package clean install uninstall template

help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

lint: ## Lint the Helm chart
	@echo "Linting Helm chart..."
	helm lint $(CHART_DIR)

test: ## Run chart tests
	@echo "Running chart tests..."
	$(SCRIPTS_DIR)/test-chart.sh

validate-versions: ## Validate version consistency
	@echo "Validating versions..."
	$(SCRIPTS_DIR)/validate-versions.sh

validate-equivalence: ## Validate equivalence with Kustomize
	@echo "Validating equivalence with Kustomize..."
	$(SCRIPTS_DIR)/validate-equivalence.sh

template: ## Generate template output
	@echo "Generating template output..."
	helm template cloudflare-operator $(CHART_DIR)

template-debug: ## Generate template output with debug info
	@echo "Generating template output with debug..."
	helm template cloudflare-operator $(CHART_DIR) --debug

package: lint test validate-versions ## Package the chart
	@echo "Packaging chart..."
	$(SCRIPTS_DIR)/package-chart.sh

install: ## Install the chart locally (requires Kubernetes cluster)
	@echo "Installing chart..."
	helm install cloudflare-operator $(CHART_DIR) \
		--create-namespace \
		--namespace cloudflare-operator-system

install-dry-run: ## Install the chart (dry-run)
	@echo "Installing chart (dry-run)..."
	helm install cloudflare-operator $(CHART_DIR) \
		--dry-run \
		--namespace cloudflare-operator-system

upgrade: ## Upgrade the chart
	@echo "Upgrading chart..."
	helm upgrade cloudflare-operator $(CHART_DIR) \
		--namespace cloudflare-operator-system

uninstall: ## Uninstall the chart
	@echo "Uninstalling chart..."
	helm uninstall cloudflare-operator \
		--namespace cloudflare-operator-system

clean: ## Clean generated files
	@echo "Cleaning generated files..."
	rm -rf $(DIST_DIR)
	rm -f *.tgz

test-install: install ## Install and run Helm tests
	@echo "Running Helm tests..."
	helm test cloudflare-operator --namespace cloudflare-operator-system

all: lint test validate-versions package ## Run all validation and package

# Development targets
dev-install: ## Install with development settings
	helm install cloudflare-operator $(CHART_DIR) \
		--create-namespace \
		--namespace cloudflare-operator-system \
		--set image.tag=latest \
		--set features.webhooks.enabled=false

dev-template: ## Template with development settings
	helm template cloudflare-operator $(CHART_DIR) \
		--set image.tag=latest \
		--set features.webhooks.enabled=false