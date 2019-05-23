#!/bin/bash

export AAD_TENANT_ID="chgeuerfte.onmicrosoft.com"
export location="westeurope"
export rg_name="spring3"
export prefix="spring3"
echo "Using Azure AD tenant ${AAD_TENANT_ID}, deploying to resource group ${rg_name} in ${location}"

#
# The Azure AD group which users must be in to access the web app
#
export AAD_GROUP="christian"

#
# Various names for resources
#
export sql_server_name="${prefix}sql"
export sql_database="${prefix}db"
export sql_username="${prefix}user"
export acr_name="${prefix}acr"
export aci_name="${prefix}aci"
export keyvault_name="${prefix}kv"
export KEYVAULT_URI="https://${keyvault_name}.vault.azure.net/"
export public_web_app_hostname="${aci_name}.${location}.azurecontainer.io"

#
# Create the resource group
#
az group create \
    --name "${rg_name}" \
    --location  "${location}"

#
# Create a bunch of random passwords
#

mkdir .passwords
export sql_password="$(openssl rand 14 -base64)"
echo "${sql_password}" > ".passwords/.${rg_name}-${prefix}-sql_password"

# export service_principal_pass="${AAD_CLIENT_ID}"
export service_principal_pass="$(openssl rand 14 -base64)"
echo "${service_principal_pass}" > ".passwords/.${rg_name}-${prefix}-service_principal_pass"

export aadGraphAPI="00000002-0000-0000-c000-000000000000"
export signInAndReadUserProfile="311a71cc-e848-46a1-bdf8-97ff7156d8e6"

export MANIFEST="[
    {
        \"resourceAppId\": \"${aadGraphAPI}\",
        \"resourceAccess\": [
            { \"id\": \"${signInAndReadUserProfile}\", \"type\": \"Scope\" }
        ]
    }
]"
echo "${MANIFEST}" > manifest.json

#export service_principal_id="${AAD_CLIENT_ID}"
export service_principal_id="$(az ad app create \
    --display-name "${prefix} demo principal" \
    --oauth2-allow-implicit-flow true \
    --credential-description "OpenSSL-generated password" \
    --key-type Symmetric \
    --key-value "${service_principal_pass}" \
    --homepage "http://${AAD_TENANT_ID}/${prefix}" \
    --identifier-uris \
        "http://${AAD_TENANT_ID}/${prefix}" \
    --reply-urls \
        "http://localhost:8080/login/oauth2/code/azure" \
        "http://${public_web_app_hostname}:8080/login/oauth2/code/azure" \
    --required-resource-accesses @manifest.json \
    --query "appId" -o tsv)"
echo "Application ID: ${service_principal_id}"
echo "${service_principal_id}" > ".passwords/.${rg_name}-${prefix}-service_principal_id"

rm manifest.json

#
# Turn on "signInAudience": "AzureADMultipleOrgs"
#
az ad app update \
    --id "${service_principal_id}" \
    --available-to-other-tenants true

#
# Convert the existing app into a service principal, so we can authorize it to call into KeyVault
#
az ad sp create \
    --id "${service_principal_id}"

# az ad app update \
#     --id "${service_principal_id}" \
#     --reply-urls \
#         "http://${public_web_app_hostname}:8080/login/oauth2/code/azure" \
#         "http://localhost:8080/login/oauth2/code/azure"

az ad app permission grant \
    --id "${service_principal_id}" \
    --api "${aadGraphAPI}"

# az ad app permission add --id "${service_principal_id}" --api "${aadGraphAPI}" --api-permissions "${signInAndReadUserProfile}=Scope"

#
# Create SQL Azure Server
#
az sql server create \
    --name "${sql_server_name}" \
    --resource-group "${rg_name}" \
    --location  "${location}" \
    --admin-user "${sql_username}" \
    --admin-password "${sql_password}"

#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# For test purposes, open up SQL Azure server's firewall to the whole world :-) !!!!!!
# don't do that at home, kids!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
export startip=0.0.0.0
export endip=223.255.255.255
az sql server firewall-rule create \
    --name FullInternetCanAccessDontDoThatInProd \
    --resource-group "${rg_name}" \
    --server "${sql_server_name}" \
    --start-ip-address $startip --end-ip-address $endip

#
# Create a database on the server
#
az sql db create \
    --name "${sql_database}" \
    --resource-group "${rg_name}" \
    --server "${sql_server_name}" \
    --service-objective Basic

#
# Helper functions
#
spring_property_name_to_keyvault_name() {
    # Azure KeyVault doesn't allow "." in names, so we need to replace the '.' by '-'
    local spring_property_name=${1}
    echo "${spring_property_name//\./-}"
}

spring_connection_string() {
    local server=${1}
    local db=${2}
    local user=${3}
    local pass=${4}

    connection_string="jdbc:sqlserver://${server}.database.windows.net:1433;"
    connection_string+="database=${db};"
    connection_string+="user=${user}@${server};"
    connection_string+="password=${pass};"
    connection_string+="encrypt=true;"
    connection_string+="trustServerCertificate=false;"
    connection_string+="hostNameInCertificate=*.database.windows.net;"
    connection_string+="loginTimeout=30;"

    echo "${connection_string}"
}

#
# Create a KeyVault
#
az keyvault create \
    --name "${keyvault_name}" \
    --resource-group "${rg_name}" \
    --location  "${location}" \
    --enabled-for-deployment true \
    --enabled-for-disk-encryption true \
    --enabled-for-template-deployment true \
    --sku standard

#
# Ensure the web app's service principal has access to KeyVault
#
az keyvault set-policy \
    --name "${keyvault_name}" \
    --spn "${service_principal_id}" \
    --secret-permission get list

#
# Store the DB connection string in KeyVault
#
az keyvault secret set \
    --vault-name "${keyvault_name}" \
    --name "$(spring_property_name_to_keyvault_name 'spring.datasource.url')" \
    --value "$(spring_connection_string $sql_server_name $sql_database $sql_username $sql_password)"

#
# Create an Azure Container Registry
#
az acr create \
    --name "${acr_name}" \
    --resource-group "${rg_name}" \
    --location  "${location}" \
    --sku Standard \
    --admin-enabled

#
# Fetch an ACR password
#
export acr_password="$(az acr credential show \
    --resource-group "${rg_name}" \
    --name "${acr_name}" \
    --query "passwords[?contains(name,'password2')].[value]" \
    -o tsv)"

#
# https://docs.microsoft.com/en-us/azure/container-registry/container-registry-tutorial-build-task
#
export TAG=springaad

#
# Please note that this step uses my personal "$github" token...
#
export acr_build_task_name="taskhelloworld"
az acr task create \
    --registry "${acr_name}" \
    --name "${acr_build_task_name}" \
    --image $TAG:{{.Run.ID}} \
    --image $TAG:latest \
    --context https://github.com/chgeuer/spring_boot_aad_kv.git \
    --branch master \
    --file Dockerfile \
    --git-access-token $github

#
# Trigger initial creation of Docker image
#
az acr task run \
    --registry "${acr_name}" \
    --name "${acr_build_task_name}"

az container create \
    --name "${aci_name}" \
    --dns-name-label "${aci_name}"\
    --resource-group "${rg_name}" \
    --location  "${location}" \
    --image "${acr_name}.azurecr.io/${TAG}:latest" \
    --registry-username "${acr_name}" \
    --registry-password "${acr_password}" \
    --ip-address Public \
    --ports 8080 \
    --protocol TCP \
    --environment-variables \
        "KEYVAULT_URI=${KEYVAULT_URI}" \
        "AAD_TENANT_ID=${AAD_TENANT_ID}" \
        "AAD_GROUP=${AAD_GROUP}" \
        "AAD_CLIENT_ID=${service_principal_id}" \
    --secure-environment-variables \
        "AAD_CLIENT_SECRET=${service_principal_pass}"

echo "Now navigate to http://${public_web_app_hostname}:8080"

# docker login "${DOCKER_REGISTRY}" \
#        --username "${DOCKER_USERNAME}" \
#        --password "${DOCKER_PASSWORD}"
