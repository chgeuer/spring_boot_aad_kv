#!/bin/bash

source ./0-variables.sh

az group create \
    --name "${rg_name}" \
    --location  "${location}"


#
# Now that the service principal exists, we launch an ARM template to create
# SQL Server, SQL Database, KeyVault and Azure Container Registry
#
az group deployment create \
    --resource-group "${rg_name}" \
    --template-file azuredeploy-0.json \
    --parameters \
"{\
    \"prefix\": { \"value\": \"${prefix}\" }, \
    \"servicePrincipalObjectID\": { \"value\": \"${service_principal_object_id}\" }, \
    \"servicePrincipalClientSecret\": { \"value\": \"${service_principal_pass}\" }, \
    \"sqlPassword\": { \"value\": \"${sql_password}\" }, \
    \"githubPersonalAccessToken\": { \"value\": \"${github}\" }, \
    \"githubRepositoryUrl\": { \"value\": \"https://github.com/chgeuer/spring_boot_aad_kv.git\" } \
}"

#
# Build the Docker image in the registry
#
az acr task run \
    --registry "${acr_name}" \
    --name "${acr_build_task_name}"

#
# Now that the Docker image is ready to use, we can trigger the compute node creation. 
#
az group deployment create \
    --resource-group "${rg_name}" \
    --template-file azuredeploy-1.json \
    --parameters "\
{ \
    \"prefix\": { \"value\": \"${prefix}\" }, \
    \"servicePrincipalApplicationID\": { \"value\": \"${service_principal_application_id}\" }, \
    \"servicePrincipalClientSecret\": { \"value\": \"${service_principal_pass}\" }, \
    \"githubPersonalAccessToken\": { \"value\": \"${github}\" }, \
    \"githubRepositoryUrl\": { \"value\": \"https://github.com/chgeuer/spring_boot_aad_kv.git\" } \
} \
"
