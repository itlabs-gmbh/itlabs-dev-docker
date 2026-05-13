# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────
GHCR_HOST    := ghcr.io/itlabs-gmbh
IMAGE_NAME   := itlabs-dev
IMAGE_TAG    ?= latest
FULL_IMAGE   := $(GHCR_HOST)/$(IMAGE_NAME):$(IMAGE_TAG)

# ─────────────────────────────────────────────────────────────────────────────
# Targets
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: build push pull run shell help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image locally
	docker build \
	  --tag $(IMAGE_NAME):$(IMAGE_TAG) \
	  .

push: build ## Build and push image to GHCR (requires docker login ghcr.io)
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(FULL_IMAGE)
	docker push $(FULL_IMAGE)
	@echo "✅  Pushed: $(FULL_IMAGE)"

pull: ## Pull latest image from GHCR
	docker pull $(FULL_IMAGE)

run: ## Start an interactive container (uses docker compose)
	docker compose run --rm dev

shell: ## Open a shell in a running itlabs-dev container
	docker exec -it itlabs-dev /bin/zsh
