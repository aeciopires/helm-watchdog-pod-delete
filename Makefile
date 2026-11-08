#-----------------------------------------------------------------------------------------
# Makefile of helm-watchdog-pod-delete
#
# Run "make" or "make help" to list all targets. Every target documented with "## " is
# listed automatically, so new targets appear in the help without extra work.
#
# Tools are managed by mise (mise.toml). When mise is installed, every command runs
# through "mise exec", so the pinned versions are used even if mise is not activated in
# your shell.
#
# Safety: every kubectl/helm command that touches a cluster uses the kind context
# (kind-$(KIND_CLUSTER_NAME)) explicitly, so a real cluster is never changed by mistake.
#-----------------------------------------------------------------------------------------

SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules --no-print-directory

#---------------------------
# VARIABLES (override with: make <target> VAR=value)
#---------------------------
ROOT_DIR              := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CHART_NAME            := helm-watchdog-pod-delete
CHART_DIR             := $(ROOT_DIR)/charts/$(CHART_NAME)
CHART_VERSION         := $(shell awk '/^version:/ {print $$2}' $(CHART_DIR)/Chart.yaml)
PACKAGES_DIR          ?= $(ROOT_DIR)/.cr-release-packages
EXAMPLES_DIR          := $(ROOT_DIR)/examples

# Kubernetes versions used to validate the manifests (kubeconform)
K8S_VERSIONS          ?= 1.34.0 1.35.0 1.36.0 1.37.0
# Kubernetes version NOT supported (must fail because of kubeVersion in Chart.yaml)
K8S_UNSUPPORTED       ?= 1.33.0

# Helm plugin used by the unit tests
HELM_UNITTEST_VERSION ?= 1.2.1
HELM_UNITTEST_URL     := https://github.com/helm-unittest/helm-unittest.git

# kind
KIND_CLUSTER_NAME     ?= watchdog
KIND_CONFIG           ?= $(EXAMPLES_DIR)/kind/kind-cluster.yaml
KIND_NODE_IMAGE       ?= kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5
KUBE_CONTEXT          := kind-$(KIND_CLUSTER_NAME)

# Local OCI registry (used by ArgoCD to pull the local chart)
REGISTRY_NAME         ?= kind-registry
REGISTRY_IMAGE        ?= registry:3.1.2
REGISTRY_PORT         ?= 5001
REGISTRY_HOST         := localhost:$(REGISTRY_PORT)

# Chart release in kind
RELEASE_NAME          ?= $(CHART_NAME)
NAMESPACE             ?= $(CHART_NAME)
LOCAL_VALUES          ?= $(EXAMPLES_DIR)/helm/values-local.yaml

# ArgoCD
ARGOCD_NAMESPACE      ?= argocd
ARGOCD_CHART_VERSION  ?= 10.15.0
ARGOCD_CHART_REPO     := https://argoproj.github.io/argo-helm
ARGOCD_APP            := $(CHART_NAME)
ARGOCD_PORT           ?= 8080

TIMEOUT               ?= 10m

# Docker image of mermaid-cli used to validate the Mermaid diagrams of the Markdown files
MERMAID_CLI_IMAGE     ?= minlag/mermaid-cli:12.0.0
MERMAID_OUT_DIR       := $(ROOT_DIR)/.mermaid-out

# Owner of the OCI repository ghcr.io/<owner>/helm-charts (used in release notes)
OCI_OWNER             ?= aeciopires

# Run tools through mise when it is available
MISE                  := $(shell command -v mise 2>/dev/null)
RUN                   := $(if $(MISE),$(MISE) exec --,)
HELM                  := $(RUN) helm
KUBECTL               := $(RUN) kubectl --context $(KUBE_CONTEXT)
KIND                  := $(RUN) kind
HELM_K8S              := $(HELM) --kube-context $(KUBE_CONTEXT)

# Colors
BLUE  := \033[36m
BOLD  := \033[1m
RESET := \033[0m

#---------------------------
##@ General
#---------------------------
.PHONY: help
help: ## Show this help (lists automatically every documented target, current and future)
	@printf "\n$(BOLD)Usage:$(RESET) make $(BLUE)<target>$(RESET) [VARIABLE=value]\n"
	@awk 'BEGIN {FS = ":.*##"} \
		/^[a-zA-Z0-9_.-]+:.*?## / { printf "  $(BLUE)%-22s$(RESET) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(BOLD)%s$(RESET)\n", substr($$0, 5) }' $(MAKEFILE_LIST)
	@printf "\n$(BOLD)Main variables:$(RESET)\n"
	@printf "  CHART_VERSION=%s KIND_CLUSTER_NAME=%s KIND_NODE_IMAGE=%s\n" "$(CHART_VERSION)" "$(KIND_CLUSTER_NAME)" "$(KIND_NODE_IMAGE)"
	@printf "  NAMESPACE=%s ARGOCD_CHART_VERSION=%s K8S_VERSIONS='%s'\n\n" "$(NAMESPACE)" "$(ARGOCD_CHART_VERSION)" "$(K8S_VERSIONS)"

#---------------------------
##@ Dependencies
#---------------------------
.PHONY: check-deps
check-deps: ## Check if all required tools are installed (and if Helm is version 4)
	@missing=0; \
	if [ -z "$(MISE)" ]; then echo "[WARN] mise not found. Recommended: https://mise.jdx.dev (run 'make install-deps')"; fi; \
	if command -v docker >/dev/null 2>&1; then echo "[OK]   docker"; else echo "[FAIL] docker not found: https://docs.docker.com/engine/install/"; missing=1; fi; \
	for tool in helm kubectl kind helm-docs kubeconform yq shellcheck actionlint trivy; do \
		if $(RUN) sh -c "command -v $$tool" >/dev/null 2>&1; then echo "[OK]   $$tool"; \
		else echo "[FAIL] $$tool not found (run 'make install-deps')"; missing=1; fi; \
	done; \
	if $(RUN) sh -c "command -v argocd" >/dev/null 2>&1; then echo "[OK]   argocd (optional)"; else echo "[WARN] argocd CLI not found (optional)"; fi; \
	helm_version="$$($(HELM) version --template '{{.Version}}' 2>/dev/null || true)"; \
	case "$$helm_version" in \
		v4.*) echo "[OK]   helm $$helm_version";; \
		*) echo "[FAIL] Helm 4 is required, found '$$helm_version' (run 'make install-deps')"; missing=1;; \
	esac; \
	if $(HELM) plugin list 2>/dev/null | grep -q '^unittest'; then echo "[OK]   helm plugin unittest"; \
	else echo "[FAIL] helm plugin unittest not found (run 'make install-deps')"; missing=1; fi; \
	if [ "$$missing" -ne 0 ]; then echo "Some dependencies are missing."; exit 1; fi; \
	echo "All dependencies are installed."

.PHONY: install-deps
install-deps: ## Install mise (if missing), all tools of mise.toml and the helm-unittest plugin
	@if ! command -v mise >/dev/null 2>&1; then \
		echo "[INFO] Installing mise (https://mise.jdx.dev/getting-started.html)..."; \
		curl -fsSL https://mise.run | sh; \
		echo "[INFO] Activate mise in your shell: https://mise.jdx.dev/getting-started.html#activate-mise"; \
	fi
	@mise_bin="$$(command -v mise || echo $$HOME/.local/bin/mise)"; \
	cd $(ROOT_DIR); \
	$$mise_bin trust $(ROOT_DIR)/mise.toml; \
	$$mise_bin install; \
	if $$mise_bin exec -- helm plugin list | grep -q '^unittest'; then \
		echo "[INFO] helm plugin unittest is already installed"; \
	else \
		$$mise_bin exec -- helm plugin install $(HELM_UNITTEST_URL) --version v$(HELM_UNITTEST_VERSION) --verify=false; \
	fi
	@command -v docker >/dev/null 2>&1 || echo "[WARN] Install docker manually: https://docs.docker.com/engine/install/"
	@$(MAKE) check-deps

#---------------------------
##@ Development and tests
#---------------------------
.PHONY: lint
lint: ## Run helm lint --strict with the default values and each file in ci/
	$(HELM) lint --strict $(CHART_DIR)
	@for values in $(CHART_DIR)/ci/*.yaml; do \
		echo "==> helm lint with $$values"; \
		$(HELM) lint --strict $(CHART_DIR) -f "$$values"; \
	done

.PHONY: unittest
unittest: ## Run the unit tests (helm-unittest) in charts/*/unittests
	$(HELM) unittest --color --strict -f 'unittests/*_test.yaml' $(CHART_DIR)

.PHONY: template
template: ## Render the chart for each file in ci/ and check that unsupported Kubernetes fails
	@for values in $(CHART_DIR)/ci/*.yaml; do \
		echo "==> helm template with $$values"; \
		$(HELM) template $(RELEASE_NAME) $(CHART_DIR) -n $(NAMESPACE) -f "$$values" > /dev/null; \
	done
	@echo "==> Kubernetes $(K8S_UNSUPPORTED) must be rejected (kubeVersion)"
	@if $(HELM) template $(RELEASE_NAME) $(CHART_DIR) --kube-version $(K8S_UNSUPPORTED) > /dev/null 2>&1; then \
		echo "[FAIL] Chart was rendered for unsupported Kubernetes $(K8S_UNSUPPORTED)"; exit 1; \
	else echo "[OK] Kubernetes $(K8S_UNSUPPORTED) rejected"; fi

.PHONY: kubeconform
kubeconform: ## Validate the rendered manifests against the schemas of K8S_VERSIONS
	@for version in $(K8S_VERSIONS); do \
		for values in $(CHART_DIR)/ci/*.yaml; do \
			echo "==> Kubernetes $$version with $$(basename $$values)"; \
			$(HELM) template $(RELEASE_NAME) $(CHART_DIR) -n $(NAMESPACE) -f "$$values" --kube-version "$$version" \
				| $(RUN) kubeconform -strict -summary -kubernetes-version "$$version"; \
		done; \
	done

.PHONY: docs
docs: ## Generate the chart README.md with helm-docs
	cd $(CHART_DIR) && $(RUN) helm-docs --sort-values-order file

.PHONY: docs-check
docs-check: ## Fail if the chart README.md is outdated (run 'make docs' and commit)
	@before="$$(mktemp)"; trap 'rm -f "$$before"' EXIT; \
	cp $(CHART_DIR)/README.md "$$before"; \
	cd $(CHART_DIR) && $(RUN) helm-docs --sort-values-order file --log-level warning; \
	if ! diff -u "$$before" $(CHART_DIR)/README.md; then \
		echo "[FAIL] $(CHART_DIR)/README.md was outdated. It was regenerated now: review and commit the changes."; exit 1; \
	fi
	@echo "[OK] README.md is updated"

.PHONY: mermaid
mermaid: ## Validate the Mermaid diagrams of all Markdown files by rendering them with mermaid-cli (docker)
	@command -v docker >/dev/null 2>&1 || { echo "[FAIL] docker not found: https://docs.docker.com/engine/install/"; exit 1; }
	@mkdir -p $(MERMAID_OUT_DIR)
	@files="$$(cd $(ROOT_DIR) && grep -rl --include='*.md' --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.mermaid-out '^```mermaid' . || true)"; \
	if [ -z "$$files" ]; then echo "[INFO] No Mermaid diagram found"; exit 0; fi; \
	failed=0; \
	for file in $$files; do \
		file="$${file#./}"; \
		echo "==> mermaid $$file"; \
		if ! docker run --rm -u "$$(id -u):$$(id -g)" \
			-v $(ROOT_DIR):/data:ro -v $(MERMAID_OUT_DIR):/out \
			$(MERMAID_CLI_IMAGE) -q -i "/data/$$file" -o "/out/$$(echo "$$file" | tr '/' '_')"; then \
			echo "[FAIL] Invalid Mermaid diagram in $$file"; failed=1; \
		fi; \
	done; \
	if [ "$$failed" -ne 0 ]; then exit 1; fi; \
	echo "[OK] All Mermaid diagrams are valid (rendered files in $(MERMAID_OUT_DIR))"

.PHONY: shellcheck
shellcheck: ## Lint the shell scripts (tests/*.sh) with shellcheck
	$(RUN) shellcheck --severity=style $(ROOT_DIR)/tests/*.sh

.PHONY: actionlint
actionlint: ## Lint the GitHub Actions workflows with actionlint
	cd $(ROOT_DIR) && $(RUN) actionlint

.PHONY: security
security: ## Scan the chart for security misconfigurations with trivy (fails on MEDIUM or higher, see .trivyignore)
	$(RUN) trivy config --ignorefile $(ROOT_DIR)/.trivyignore --exit-code 1 --severity MEDIUM,HIGH,CRITICAL $(CHART_DIR)
	@for values in $(CHART_DIR)/ci/*.yaml; do \
		echo "==> trivy with $$values"; \
		$(RUN) trivy config --quiet --ignorefile $(ROOT_DIR)/.trivyignore --exit-code 1 --severity MEDIUM,HIGH,CRITICAL --helm-values "$$values" $(CHART_DIR); \
	done

.PHONY: test
test: lint template unittest kubeconform shellcheck actionlint security docs-check ## Run all static tests (lint, template, unittest, kubeconform, shellcheck, actionlint, security, docs-check)
	@echo "[OK] All static tests passed"

.PHONY: package
package: ## Package the chart with Helm 4 in .cr-release-packages/
	@mkdir -p $(PACKAGES_DIR)
	$(HELM) package $(CHART_DIR) -d $(PACKAGES_DIR)

.PHONY: version-check
version-check: ## Validate SemVer of Chart.yaml (and that TAG=x.y.z matches it, if TAG is set)
	@echo "$(CHART_VERSION)" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$$' \
		|| { echo "[FAIL] Chart version '$(CHART_VERSION)' is not a valid SemVer 2.0.0"; exit 1; }
	@if [ -n "$(TAG)" ] && [ "$(TAG)" != "$(CHART_VERSION)" ]; then \
		echo "[FAIL] Tag '$(TAG)' does not match the chart version '$(CHART_VERSION)' in Chart.yaml"; exit 1; \
	fi
	@grep -q '^## \[$(CHART_VERSION)\]' $(ROOT_DIR)/CHANGELOG.md \
		|| { echo "[FAIL] CHANGELOG.md has no section '## [$(CHART_VERSION)]'"; exit 1; }
	@echo "[OK] Chart version $(CHART_VERSION)$(if $(TAG), matches tag $(TAG),) and is documented in CHANGELOG.md"

.PHONY: release-notes
release-notes: ## Print the release notes of CHART_VERSION (section of CHANGELOG.md + install instructions)
	@awk -v version="$(CHART_VERSION)" ' \
		index($$0, "## [" version "]") == 1 { found = 1; next } \
		found && /^## \[/ { exit } \
		found { print }' $(ROOT_DIR)/CHANGELOG.md
	@printf '\n### Install\n\n'
	@printf '```bash\n# OCI registry (recommended)\nhelm install %s oci://ghcr.io/%s/helm-charts/%s --version %s -n %s --create-namespace\n\n' \
		"$(CHART_NAME)" "$(OCI_OWNER)" "$(CHART_NAME)" "$(CHART_VERSION)" "$(CHART_NAME)"
	@printf '# Helm repository\nhelm repo add %s https://%s.github.io/%s\nhelm install %s %s/%s --version %s -n %s --create-namespace\n```\n' \
		"$(CHART_NAME)" "$(OCI_OWNER)" "$(CHART_NAME)" "$(CHART_NAME)" "$(CHART_NAME)" "$(CHART_NAME)" "$(CHART_VERSION)" "$(CHART_NAME)"

.PHONY: clean
clean: ## Remove generated packages and temporary files
	rm -rf $(PACKAGES_DIR) $(CHART_DIR)/packages $(CHART_DIR)/.helm $(ROOT_DIR)/.cr-index $(MERMAID_OUT_DIR)

#---------------------------
##@ Local cluster (kind)
#---------------------------
.PHONY: kind-create
kind-create: ## Create the kind cluster (1 control-plane + 2 workers) and the local OCI registry
	@if $(KIND) get clusters 2>/dev/null | grep -qx "$(KIND_CLUSTER_NAME)"; then \
		echo "[INFO] kind cluster '$(KIND_CLUSTER_NAME)' already exists"; \
	else \
		$(KIND) create cluster --name $(KIND_CLUSTER_NAME) --config $(KIND_CONFIG) --image $(KIND_NODE_IMAGE) --wait 5m; \
	fi
	@$(MAKE) registry-create
	$(KUBECTL) wait --for=condition=Ready nodes --all --timeout=5m
	$(KUBECTL) get nodes -o wide

.PHONY: kind-delete
kind-delete: registry-delete ## Delete the kind cluster and the local OCI registry
	$(KIND) delete cluster --name $(KIND_CLUSTER_NAME)

.PHONY: registry-create
registry-create: ## Create the local OCI registry (localhost:5001) connected to the kind network
	@if [ "$$(docker inspect -f '{{.State.Running}}' $(REGISTRY_NAME) 2>/dev/null || true)" != "true" ]; then \
		docker rm -f $(REGISTRY_NAME) >/dev/null 2>&1 || true; \
		docker run -d --restart=unless-stopped --name $(REGISTRY_NAME) \
			-p 127.0.0.1:$(REGISTRY_PORT):5000 $(REGISTRY_IMAGE) >/dev/null; \
		echo "[INFO] Registry $(REGISTRY_NAME) running in $(REGISTRY_HOST)"; \
	fi
	@if [ "$$(docker inspect -f '{{json .NetworkSettings.Networks.kind}}' $(REGISTRY_NAME))" = "null" ]; then \
		docker network connect kind $(REGISTRY_NAME); \
	fi

.PHONY: registry-delete
registry-delete: ## Delete the local OCI registry
	docker rm -f $(REGISTRY_NAME) >/dev/null 2>&1 || true

#---------------------------
##@ Deploy without ArgoCD (Helm)
#---------------------------
.PHONY: deploy
deploy: ## Deploy the local chart in kind with Helm 4 (no ArgoCD)
	@if $(KUBECTL) get applications.argoproj.io $(ARGOCD_APP) -n $(ARGOCD_NAMESPACE) >/dev/null 2>&1; then \
		echo "[FAIL] The chart is managed by ArgoCD. Run 'make undeploy-argocd' first."; exit 1; \
	fi
	$(HELM_K8S) upgrade --install $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) --create-namespace \
		-f $(LOCAL_VALUES) \
		--wait --timeout $(TIMEOUT) --rollback-on-failure

.PHONY: helm-test
helm-test: ## Run "helm test" for the release deployed with "make deploy"
	$(HELM_K8S) test $(RELEASE_NAME) --namespace $(NAMESPACE) --logs --timeout 5m

.PHONY: undeploy
undeploy: ## Remove the chart deployed with "make deploy"
	$(HELM_K8S) uninstall $(RELEASE_NAME) --namespace $(NAMESPACE) --wait --ignore-not-found
	$(KUBECTL) delete namespace $(NAMESPACE) --ignore-not-found

#---------------------------
##@ ArgoCD
#---------------------------
.PHONY: argocd-install
argocd-install: ## Install ArgoCD in kind (Helm chart argo-cd, version ARGOCD_CHART_VERSION)
	$(HELM_K8S) upgrade --install argocd argo-cd --repo $(ARGOCD_CHART_REPO) --version $(ARGOCD_CHART_VERSION) \
		--namespace $(ARGOCD_NAMESPACE) --create-namespace \
		-f $(EXAMPLES_DIR)/argocd/argocd-values.yaml \
		--wait --timeout $(TIMEOUT)

.PHONY: argocd-uninstall
argocd-uninstall: ## Uninstall ArgoCD from kind
	$(HELM_K8S) uninstall argocd --namespace $(ARGOCD_NAMESPACE) --wait --ignore-not-found
	$(KUBECTL) delete namespace $(ARGOCD_NAMESPACE) --ignore-not-found

.PHONY: argocd-password
argocd-password: ## Show the initial password of the ArgoCD "admin" user
	@$(KUBECTL) -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

.PHONY: argocd-ui
argocd-ui: ## Access the ArgoCD UI in http://localhost:8080 (port-forward)
	@echo "[INFO] Open http://localhost:$(ARGOCD_PORT) (user: admin, password: 'make argocd-password')"
	$(KUBECTL) -n $(ARGOCD_NAMESPACE) port-forward --address 127.0.0.1 svc/argocd-server $(ARGOCD_PORT):80

#---------------------------
##@ Deploy with ArgoCD
#---------------------------
.PHONY: deploy-argocd
deploy-argocd: registry-create ## Push the local chart to the local OCI registry and deploy it with an ArgoCD Application
	@if $(HELM_K8S) status $(RELEASE_NAME) -n $(NAMESPACE) >/dev/null 2>&1; then \
		echo "[FAIL] The chart is deployed with Helm. Run 'make undeploy' first."; exit 1; \
	fi
	@tmp_dir="$$(mktemp -d)"; trap 'rm -rf "$$tmp_dir"' EXIT; \
	dev_version="$(CHART_VERSION)-dev.$$(date -u +%Y%m%d%H%M%S)"; \
	echo "[INFO] Packaging chart version $$dev_version"; \
	$(HELM) package $(CHART_DIR) --version "$$dev_version" -d "$$tmp_dir"; \
	$(HELM) push "$$tmp_dir/$(CHART_NAME)-$$dev_version.tgz" oci://$(REGISTRY_HOST)/charts --plain-http; \
	$(KUBECTL) apply -f $(EXAMPLES_DIR)/argocd/repository-local-registry.yaml; \
	$(KUBECTL) apply -f $(EXAMPLES_DIR)/argocd/application.yaml; \
	echo "[INFO] Forcing ArgoCD to look for the new chart version..."; \
	$(KUBECTL) -n $(ARGOCD_NAMESPACE) annotate applications.argoproj.io $(ARGOCD_APP) argocd.argoproj.io/refresh=hard --overwrite; \
	echo "[INFO] Waiting ArgoCD to sync revision $$dev_version and the Application to be Healthy..."; \
	$(KUBECTL) -n $(ARGOCD_NAMESPACE) wait applications.argoproj.io/$(ARGOCD_APP) \
		--for=jsonpath='{.status.sync.revision}'="$$dev_version" --timeout=5m; \
	$(KUBECTL) -n $(ARGOCD_NAMESPACE) wait applications.argoproj.io/$(ARGOCD_APP) \
		--for=jsonpath='{.status.sync.status}'=Synced --timeout=5m; \
	$(KUBECTL) -n $(ARGOCD_NAMESPACE) wait applications.argoproj.io/$(ARGOCD_APP) \
		--for=jsonpath='{.status.health.status}'=Healthy --timeout=5m
	$(KUBECTL) -n $(ARGOCD_NAMESPACE) get applications.argoproj.io $(ARGOCD_APP) \
		-o custom-columns='NAME:.metadata.name,REVISION:.status.sync.revision,SYNC:.status.sync.status,HEALTH:.status.health.status'

.PHONY: undeploy-argocd
undeploy-argocd: ## Remove the ArgoCD Application (and the resources of the chart)
	$(KUBECTL) -n $(ARGOCD_NAMESPACE) delete applications.argoproj.io $(ARGOCD_APP) --ignore-not-found --wait --timeout=5m
	$(KUBECTL) delete -f $(EXAMPLES_DIR)/argocd/repository-local-registry.yaml --ignore-not-found
	$(KUBECTL) delete namespace $(NAMESPACE) --ignore-not-found

#---------------------------
##@ Validation in kind
#---------------------------
.PHONY: test-crash
test-crash: ## Create pods that fail on purpose (namespace test-crash) to validate the watchdog
	$(KUBECTL) apply -f $(EXAMPLES_DIR)/test-crash-pods.yaml

.PHONY: test-crash-clean
test-crash-clean: ## Remove the pods that fail on purpose
	$(KUBECTL) delete -f $(EXAMPLES_DIR)/test-crash-pods.yaml --ignore-not-found

.PHONY: logs
logs: ## Follow the logs of the watchdog
	$(KUBECTL) -n $(NAMESPACE) logs -f deploy/$(RELEASE_NAME)

.PHONY: e2e
e2e: ## End-to-end test in kind (deploy with Helm, helm test, crash pods are deleted, undeploy)
	@$(MAKE) deploy
	@$(MAKE) helm-test
	KUBE_CONTEXT=$(KUBE_CONTEXT) NAMESPACE=$(NAMESPACE) DEPLOYMENT=$(RELEASE_NAME) \
		CRASH_MANIFEST=$(EXAMPLES_DIR)/test-crash-pods.yaml $(RUN) $(ROOT_DIR)/tests/e2e.sh
	@$(MAKE) undeploy

.PHONY: e2e-argocd
e2e-argocd: ## End-to-end test in kind using ArgoCD (requires 'make argocd-install')
	@$(MAKE) deploy-argocd
	KUBE_CONTEXT=$(KUBE_CONTEXT) NAMESPACE=$(NAMESPACE) DEPLOYMENT=$(RELEASE_NAME) \
		CRASH_MANIFEST=$(EXAMPLES_DIR)/test-crash-pods.yaml $(RUN) $(ROOT_DIR)/tests/e2e.sh

#---------------------------
##@ Full stack
#---------------------------
.PHONY: stack-up
stack-up: ## Start the whole stack: kind + local registry + ArgoCD + local chart deployed by ArgoCD
	@$(MAKE) kind-create
	@$(MAKE) argocd-install
	@$(MAKE) deploy-argocd
	@echo ""
	@echo "[OK] Stack is ready. Next steps:"
	@echo "  make test-crash       # create pods with errors"
	@echo "  make logs             # follow the watchdog logs"
	@echo "  make argocd-password  # show the ArgoCD admin password"
	@echo "  make argocd-ui        # open the ArgoCD UI in http://localhost:$(ARGOCD_PORT)"
	@echo "  make stack-down       # remove everything"

.PHONY: stack-down
stack-down: kind-delete ## Remove the whole stack (kind cluster and local registry)
