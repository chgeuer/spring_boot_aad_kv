#!/bin/bash

source ./0-variables.sh

./1-create-service-principal.sh

#
# Create the resource group
#
az group create \
    --name "${rg_name}" \
    --location  "${location}"

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
    --query "passwords[0].value" \
    -o tsv)"

#
# https://docs.microsoft.com/en-us/azure/container-registry/container-registry-tutorial-build-task
#
#
# Please note that this step uses my personal "$github" token...
#
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
        "KEYVAULT_URI=${keyvault_url}" \
        "AAD_TENANT_ID=${AAD_TENANT_ID}" \
        "AAD_GROUP=${AAD_GROUP}" \
        "AAD_CLIENT_ID=${service_principal_id}" \
    --secure-environment-variables \
        "AAD_CLIENT_SECRET=${service_principal_pass}"

echo "Now navigate to http://${public_web_app_hostname}:8080"
