VARS_FILE ?= variables.tfvars
PROJECT_ID ?=
REGION     ?=

BOOTSTRAP_PLAN_ARGS = -var 'project_id=$(PROJECT_ID)' -var 'region=$(REGION)'

.PHONY: activate_apis bootstrap_apply deploy

bootstrap: activate_apis bootstrap_apply

activate_apis:
	gcloud services enable \
		iam.googleapis.com \
		cloudresourcemanager.googleapis.com \
		serviceusage.googleapis.com \
		artifactregistry.googleapis.com \
		container.googleapis.com \
		storage.googleapis.com \
		orgpolicy.googleapis.com \
		compute.googleapis.com && \
	echo "Waiting for API propagation..." && sleep 30
	
bootstrap_apply:
	cd bootstrap && \
	terraform init && \
	terraform validate && \
	terraform apply $(BOOTSTRAP_PLAN_ARGS) \

deploy:
	cd infra && \
	terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=gke" && \
	terraform validate && \
	terraform apply -var-file=../$(VARS_FILE)

destroy_gke:
	cd infra && \
	terraform destroy -target=google_container_node_pool.primary_nodes -auto-approve && \
	terraform destroy -target=google_container_cluster.gke_cluster -auto-approve