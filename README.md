# Market Streaming Infrastructure Terraform

Terraform configuration for provisioning the Google Cloud infrastructure used by the real-time market-data pipeline.

This repository is part of the [Real-Time Market Data System](https://github.com/charlescol/real-time-market-data-system). It creates the cloud resources required before applying the Kubernetes and GitOps configuration from [market-streaming-infra-gitops](https://github.com/charlescol/market-streaming-infra-gitops).

## Scope

This repository provisions the infrastructure layer of the system on Google Cloud.

It includes:

- GKE cluster resources
- IAM roles and service accounts
- Artifact Registry resources
- Google Cloud Storage buckets
- Persistent storage configuration
- Required Google Cloud services and APIs
- Terraform state backend setup

Application deployments, Kubernetes manifests, Flux resources, and Helm releases are managed in the GitOps repository.

## Repository structure

```
.
├── bootstrap/   # One-time setup for Terraform state storage
├── core/        # Privileged resources such as service accounts and IAM
├── infra/       # Main cloud infrastructure, including GKE and storage
├── makefile
└── variables.tfvars
```

## Deployment flow

The infrastructure is split into three layers.

### 1. Bootstrap

The bootstrap layer creates the Terraform state storage and enables the initial resources required to manage state remotely.

```
cd bootstrap
make bootstrap PROJECT_ID=my-project-id ZONE=asia-northeast1-c CLUSTER_NAME=my-gke-cluster
```

### 2. Core infrastructure

The core layer manages privileged resources such as service accounts and IAM bindings.

```
cd core
make core PROJECT_ID=my-project-id ZONE=asia-northeast1-c CLUSTER_NAME=my-gke-cluster
```

This step should be run with an account that has the required administrative permissions.

### 3. Main infrastructure

The infra layer provisions the main Google Cloud resources used by the pipeline.

```
cd infra
make deploy PROJECT_ID=my-project-id ZONE=asia-northeast1-c CLUSTER_NAME=my-gke-cluster VARS_FILE=../variables.tfvars
```

This step is intended to be run with the Terraform service account created by the core layer.

## Usage

List available commands.

```
make help
```

Authenticate with the Google Cloud CLI before running Terraform commands.

```
gcloud auth application-default login
```

Make sure the target project, zone, and cluster name match the values used by the GitOps deployment.
