#!/usr/bin/env bash

# initialize with Azure backend
terraform init -backend=true -backend-config="backend.tfvars"
# plan
terraform plan
# apply
terraform apply