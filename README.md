# How to use

## Bootstrap once

The following command will need to be run once to enable all the required APIs and create a bucket for storing the Terraform state:

```bash
 make bootstrap PROJECT_ID=myprojectid REGION=europe-west1
```

## Deploy core infra

After logging to an account with a privileged role, run the following command:

```bash
 make core PROJECT_ID=myprojectid REGION=europe-west1
```

It is used to manage resources that necessitate a privileged role such as service accounts, IAM roles, etc.

## Deploy infra

The following command will deploy the infrastructure:

```bash
make deploy PROJECT_ID=myprojectid VARS_FILE=variables.tfvars
```

This is recommanded to be run using the terraform service account created by the previous command.
