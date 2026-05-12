# ─────────────────────────────────────────────────────────────────────────────
# Configuration – adjust to your ACR
# ─────────────────────────────────────────────────────────────────────────────
ACR_NAME     ?= yourregistry          # Azure Container Registry name (without .azurecr.io)
ACR_HOST     := $(ACR_NAME).azurecr.io
IMAGE_NAME   := itlabs-dev
IMAGE_TAG    ?= latest
FULL_IMAGE   := $(ACR_HOST)/$(IMAGE_NAME):$(IMAGE_TAG)

# ─────────────────────────────────────────────────────────────────────────────
# Targets
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: build push pull login run shell help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

login: ## Log in to Azure Container Registry (requires az CLI)
	az acr login --name $(ACR_NAME)

build: ## Build the Docker image locally
	docker build \
	  --tag $(IMAGE_NAME):$(IMAGE_TAG) \
	  --tag $(FULL_IMAGE) \
	  .

push: login build ## Build and push image to ACR
	docker push $(FULL_IMAGE)
	@echo "✅  Pushed: $(FULL_IMAGE)"

pull: login ## Pull latest image from ACR
	docker pull $(FULL_IMAGE)

run: ## Start an interactive container (uses docker compose)
	docker compose run --rm dev

shell: ## Open a shell in a running itlabs-dev container
	docker exec -it itlabs-dev /bin/zsh
