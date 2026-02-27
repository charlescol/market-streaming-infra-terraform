# How to use

To get the list of available commands, run:

```bash
 make help
```

**Note:** use the gcloud CLI to authenticate before running the commands.

## Bootstrap once

The following command will need to be run once to enable all the required APIs and create a bucket for storing the Terraform state:

```bash
cd bootstrap
 make bootstrap PROJECT_ID=myprojectid ZONE=asia-northeast1-c CLUSTER_NAME=my-gke-cluster
```

## Deploy core infra

After logging to an account with a privileged role, run the following command:

```bash
cd core
 make core PROJECT_ID=myprojectid ZONE=asia-northeast1-c CLUSTER_NAME=my-gke-cluster
```

It is used to manage resources that necessitate a privileged role such as service accounts, IAM roles, etc.

## Deploy infra

The following command will deploy the infrastructure:

```bash
cd infra
make deploy PROJECT_ID=myprojectid ZONE=asia-northeast1-c CLUSTER_NAME=my-gke-cluster VARS_FILE=../variables.tfvars
```

This is recommanded to be run using the terraform service account created by the previous command.
