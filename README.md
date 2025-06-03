# How to use

## Bootstrap once

After logging to an account with the right permissions, run the following command:

```bash
 make bootstrap PROJECT_ID=myprojectid REGION=europe-west1
```

It will enable all the required APIs and create a service account and backend for Terraform.

## Deploy infra

The following command will deploy the infrastructure:

```bash
make deploy PROJECT_ID=myprojectid
```

This is recommanded to be run using the service account created by the bootstrap command.
