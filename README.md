# How to use

## Bootstrap once

After logging to an account with a privileged role, run the following command:

```bash
 make bootstrap PROJECT_ID=myprojectid REGION=europe-west1
```

It will enable all the required APIs, create the service accounts, and create a bucket for storing the Terraform state.

## Deploy infra

The following command will deploy the infrastructure:

```bash
make deploy PROJECT_ID=myprojectid
```

This is recommanded to be run using the service account created by the bootstrap command.
