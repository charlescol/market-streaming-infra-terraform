VARS_FILE ?= variables.tfvars
PROJECT_ID ?=
REGION     ?=

PLAN_ARGS = -var 'project_id=$(PROJECT_ID)' -var 'region=$(REGION)'

.PHONY: activate_apis bootstrap_apply deploy destroy_gke core destroy_all help _confirm bootstrap check_vars

bootstrap: activate_apis bootstrap_apply


help: ## Display this help
	@echo "Usage: make <target> [PROJECT_ID=...] [REGION=...] [VARS_FILE=...]"
	@echo ""
	@echo "Targets :"
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) \
		| grep -v '^_' \
		| awk 'BEGIN {FS = ":.*?##"}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

activate_apis: ## Activate required APIs
	gcloud services enable \
		iam.googleapis.com \
		cloudresourcemanager.googleapis.com \
		serviceusage.googleapis.com \
		artifactregistry.googleapis.com \
		container.googleapis.com \
		storage.googleapis.com \
		orgpolicy.googleapis.com \
		secretmanager.googleapis.com \
		compute.googleapis.com \
		--project=$(PROJECT_ID)
	@echo "Waiting for API propagation..." && sleep 30
	
bootstrap_apply: ## Apply bootstrap infrastructure
	@$(MAKE) _check_vars
	@cd bootstrap && { \
		terraform init && \
		terraform validate && \
		terraform apply $(PLAN_ARGS) ; \
	}

core: ## Deploy core infrastructure
	@$(MAKE) _check_vars
	@cd core && { \
		terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=core" && \
		terraform validate && \
		terraform apply $(PLAN_ARGS) ; \
	}

deploy: ## Deploy infrastructure
	@$(MAKE) _check_vars
	@cd infra && { \
		terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=gke" && \
		terraform validate && \
		terraform apply -var-file=../$(VARS_FILE) ; \
	}

destroy_gke: ## Destroy GKE cluster and node pool
	@$(MAKE) _check_vars
	@echo "⚠️  You are about to destroy the GKE cluster and node pool. This action is irreversible."
	@$(MAKE) _confirm
	@cd infra && { \
		set -e; \
		terraform destroy -var-file=../$(VARS_FILE) -target=google_container_node_pool.primary_nodes -auto-approve && \
		terraform destroy -var-file=../$(VARS_FILE) -target=google_container_cluster.gke_cluster -auto-approve ; \
	}


destroy_all: ## Destroy all resources
	@$(MAKE) _check_vars
	@echo "⚠️  You are about to destroy all resources. This action is irreversible."
	@$(MAKE) _confirm

	@cd infra && { \
		set -e; \
		terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=gke" && \
		terraform destroy -var-file=../$(VARS_FILE) -auto-approve ; \
	}

	@cd core && { \
		set -e; \
		terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=core" && \
		terraform destroy $(PLAN_ARGS) -auto-approve ; \
	}

	@cd bootstrap && { \
		set -e; \
		terraform init && \
		terraform destroy $(PLAN_ARGS) -auto-approve ; \
	}

	@gcloud services disable \
		iam.googleapis.com \
		cloudresourcemanager.googleapis.com \
		serviceusage.googleapis.com \
		artifactregistry.googleapis.com \
		container.googleapis.com \
		storage.googleapis.com \
		orgpolicy.googleapis.com \
		secretmanager.googleapis.com \
		compute.googleapis.com \
		--project=$(PROJECT_ID) \
		--force
		
	@echo "All resources have been destroyed successfully."

_confirm:
	@read -p "❓ Are you sure you want to continue? (yes/no): " confirm; \
	if [ "$$confirm" != "yes" ]; then \
		echo "❌ Operation cancelled."; \
		exit 1; \
	fi

_check_vars:
	@{ \
	  if [ -z "$(PROJECT_ID)" ]; then \
	    echo "❌ PROJECT_ID is not set. Use make <target> PROJECT_ID=your-project-id"; \
	    exit 1; \
	  fi; \
	  if [ -z "$(REGION)" ]; then \
	    echo "❌ REGION is not set. Use make <target> REGION=your-region"; \
	    exit 1; \
	  fi; \
	}