VARS_FILE ?= variables.tfvars
PROJECT_ID ?=
REGION     ?=

BOOTSTRAP_PLAN_ARGS = -var 'project_id=$(PROJECT_ID)' -var 'region=$(REGION)'
PLAN_FILE = temp/deployment_plan.tfplan

.PHONY:  apply_plan bootstrap_plan_only deploy

bootstrap: bootstrap_plan_only apply_plan


bootstrap_plan_only:
	cd bootstrap && \
	terraform init && \
	terraform validate && \
	mkdir 
	terraform plan $(BOOTSTRAP_PLAN_ARGS) -out="$(PLAN_FILE)" && \
	terraform show "$(PLAN_FILE)" && \
	bootstrap_apply_plan

deploy:
	cd infra && \
	terraform init && \
	terraform validate && \
	terraform plan -var-file="variables.tfvars" -out="deployment_plan.tfplan" && \
	terraform show deployment_plan.tfplan && \
	terraform apply deployment_plan.tfplan

apply_plan:
	@echo "Appliquer ce plan ? [y/N] " && read confirm && \
	if [ "$$confirm" = "y" ]; then \
		cd bootstrap && terraform apply "$(PLAN_FILE)"; \
	else \
		echo "Application annulée."; \
	fi