VARS_FILE ?= variables.tfvars
PROJECT_ID ?=
REGION     ?=

BOOTSTRAP_PLAN_ARGS = -var 'project_id=$(PROJECT_ID)' -var 'region=$(REGION)'

.PHONY:  apply_plan bootstrap_plan_only deploy

bootstrap: activate_apis bootstrap_plan_only

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
	
bootstrap_plan_only:
	cd bootstrap && \
	terraform init && \
	terraform validate && \
	terraform apply $(BOOTSTRAP_PLAN_ARGS) \

deploy:
	cd infra && \
	terraform init -backend-config="bucket=tfstate-$(PROJECT_ID)" -backend-config="prefix=gke" && \
	terraform validate && \
	terraform apply -var-file=../$(VARS_FILE)
