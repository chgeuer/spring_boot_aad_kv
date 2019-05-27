#!/bin/bash

source ./0-variables.sh

#
# Now that the service principal exists, we can either create resources step-by-step,
# or launch an ARM template
#
az group deployment create \
    --resource-group "${rg_name}" \
    --template-file azuredeploy.json \
    --parameters \
"{\
    \"prefix\": { \"value\": \"${prefix}\" }, \
    \"servicePrincipalObjectID\": { \"value\": \"${service_principal_id}\" }, \
    \"servicePrincipalClientSecret\": { \"value\": \"${service_principal_pass}\" }, \
    \"sqlPassword\": { \"value\": \"${sql_password}\" }, \
    \"githubPersonalAccessToken\": { \"value\": \"${github}\" }, \
    \"githubRepositoryUrl\": { \"value\": \"https://github.com/chgeuer/spring_boot_aad_kv.git\" } \
}"


az acr task run \
    --registry "${acr_name}" \
    --name "${acr_build_task_name}"


az group deployment create \
    --resource-group "${rg_name}" \
    --template-file azuredeploy-aci.json \
    --parameters "\
{ \
    \"prefix\": { \"value\": \"${prefix}\" }, \
    \"servicePrincipalObjectID\": { \"value\": \"$(cat .passwords/.${rg_name}-${prefix}-service_principal_id)\" }, \
    \"servicePrincipalClientSecret\": { \"value\": \"$(cat .passwords/.${rg_name}-${prefix}-service_principal_pass)\" }, \
    \"githubPersonalAccessToken\": { \"value\": \"${github}\" }, \
    \"githubRepositoryUrl\": { \"value\": \"https://github.com/chgeuer/spring_boot_aad_kv.git\" } \
} \
"
