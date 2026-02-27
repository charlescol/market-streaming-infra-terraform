VARS_FILE ?= variables.tfvars
CLUSTER_NAME ?= prod-gke-tokyo-an1-cluster
PROJECT_ID ?=
ZONE ?=
REGION ?= $(shell echo "$(ZONE)" | sed -E 's/-[a-z]$$//')

TF_ARGS_INFRA = -var-file=$(VARS_FILE) \
	-var="project_id=$(PROJECT_ID)" -var="zone=$(ZONE)" -var="cluster_name=$(CLUSTER_NAME)" -var="region=$(REGION)"

TF_ARGS_CORE_BOOTSTRAP = \
	-var="project_id=$(PROJECT_ID)" -var="zone=$(ZONE)" -var="cluster_name=$(CLUSTER_NAME)" -var="region=$(REGION)"

.PHONY: activate_apis bootstrap_apply deploy destroy_gke core destroy_all help _confirm bootstrap _check_vars

bootstrap: activate_apis bootstrap_apply

help: ## Display this help
	@echo "Usage: make <target> [PROJECT_ID=...] [ZONE=...] [VARS_FILE=...] [CLUSTER_NAME=...]"
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
		terraform apply $(TF_ARGS_CORE_BOOTSTRAP) ; \
	}

core: ## Deploy core infrastructure
	@$(MAKE) _check_vars
	@cd core && { \
		terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=core" && \
		terraform validate && \
		terraform apply $(TF_ARGS_CORE_BOOTSTRAP) ; \
	}

deploy: ## Deploy infrastructure
	@$(MAKE) _check_vars
	@cd infra && { \
		terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=gke" && \
		terraform validate && \
		terraform apply $(TF_ARGS_INFRA); \
	}

destroy_gke: ## Destroy GKE cluster and node pool
	@$(MAKE) _check_vars
	@echo "⚠️  You are about to destroy the GKE cluster and node pool. This action is irreversible."
	@$(MAKE) _confirm
	@cd infra && { \
		set -e; \
		terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=gke" && \
		terraform destroy $(TF_ARGS_INFRA) -target=google_container_cluster.gke_cluster -auto-approve; \
	}
	@$(MAKE) remove_pvcs
	@$(MAKE) remove_certs

destroy_druid_storage: ## Destroy DRUID storage
	@$(MAKE) _check_vars
	@echo "⚠️  You are about to destroy DRUID storage. This action is irreversible."
	@$(MAKE) _confirm
	@cd infra && { \
		set -e; \
		terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=gke" && \
		terraform destroy $(TF_ARGS_INFRA) -target=google_storage_bucket.druid_storage -auto-approve; \
	}

destroy_all: ## Destroy all resources
	@$(MAKE) _check_vars
	@echo "⚠️  You are about to destroy all resources. This action is irreversible."
	@$(MAKE) _confirm

	@cd infra && { \
		set -e; \
		terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=gke" && \
		terraform destroy $(TF_ARGS_INFRA) -auto-approve; \
	}

	@cd core && { \
		set -e; \
		terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=core" && \
		terraform destroy $(TF_ARGS_CORE_BOOTSTRAP) -auto-approve; \
	}

	@cd bootstrap && { \
		set -e; \
		terraform init && \
		terraform destroy $(TF_ARGS_CORE_BOOTSTRAP) -auto-approve; \
	}

	@$(MAKE) remove_pvcs
	@$(MAKE) remove_certs

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

remove_pvcs: ## Remove all persistent volume claims with a Retain policy. This is useful to clean when the cluster is destroyed but the PVC were not deleted before. 
	@set -e; \
	DISKS=$$(gcloud compute disks list \
		--project "$(PROJECT_ID)" \
		--filter='zone:$(ZONE) AND labels.goog-k8s-cluster-name=$(CLUSTER_NAME) AND name~"^pvc-"' \
		--format='value(name,zone)'); \
	if [ -z "$$DISKS" ]; then \
		echo "✅ No pvc-* disks found for cluster $(CLUSTER_NAME) in $(ZONE)."; \
		exit 0; \
	fi; \
	echo "$$DISKS" | while read DISK DISK_ZONE; do \
		gcloud compute disks delete "$$DISK" --zone "$$DISK_ZONE" --project "$(PROJECT_ID)" --quiet; \
	done

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
	  if [ -z "$(ZONE)" ]; then \
	    echo "❌ ZONE is not set. Use make <target> ZONE=your-zone"; \
	    exit 1; \
	  fi; \
	  if [ -z "$(CLUSTER_NAME)" ]; then \
	    echo "❌ CLUSTER_NAME is not set. Use make <target> CLUSTER_NAME=your-cluster-name"; \
	    exit 1; \
	  fi; \
	  if [ -z "$(REGION)" ]; then \
	    echo "❌ REGION could not be derived from ZONE=$(ZONE)"; \
	    exit 1; \
	  fi; \
	}

remove_certs: ## Remove all managed certificates created by the infrastructure
	@echo "Removing managed SSL certificates..."
	@for cert in $(shell gcloud compute ssl-certificates list --global --format="value(name)" | grep '^mcrt-'); do \
		echo "Deleting certificate: $$cert"; \
		gcloud compute ssl-certificates delete "$$cert" --global --quiet; \
	done
	@echo "All managed certificates have been deleted."

test_stockout: ## Test e2-medium availability in asia-northeast1 a/b/c (create+delete)
	@set -e; \
	for z in asia-northeast1-a asia-northeast1-b asia-northeast1-c; do \
	  n="stockout-test-$${z##*-}"; \
	  echo "== $$z =="; \
	  if gcloud compute instances create "$$n" --zone="$$z" --machine-type=e2-medium --image-family=debian-12 --image-project=debian-cloud --quiet; then \
	    echo "OK"; \
	    gcloud compute instances delete "$$n" --zone="$$z" --quiet; \
	  else \
	    echo "NO"; \
	  fi; \
	done