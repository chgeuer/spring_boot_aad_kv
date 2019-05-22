#!/bin/bash

export rg_name="spring"
export prefix="chgeuerconcur"
export location="westeurope"

export sql_server_name="${prefix}sql"
export sql_database="${prefix}db"
export sql_username="${prefix}user"
export sql_password="$(openssl rand 14 -base64)"

echo "${sql_password}" > ./.sql_password

export keyvault_name="${prefix}kv"
export KEYVAULT_URI="https://${keyvault_name}.vault.azure.net/"
export service_principal_id="${AAD_CLIENT_ID}"

export acr_name="${prefix}acr"



az sql server create \
    --name "${sql_server_name}" \
    --resource-group "${rg_name}" \
    --location  "${location}" \
    --admin-user "${sql_username}" \
    --admin-password "${sql_password}"

#
# For test purposes, open up SQL Azure's firewall to the whole world :-)
#
export startip=0.0.0.0
export endip=223.255.255.255
az sql server firewall-rule create \
    --name FullInternetCanAccessDontDoThatInProd \
    --resource-group "${rg_name}" \
    --server "${sql_server_name}" \
    --start-ip-address $startip --end-ip-address $endip

az sql db create \
    --name "${sql_database}" \
    --resource-group "${rg_name}" \
    --server "${sql_server_name}" \
    --service-objective Basic

az keyvault create --name "${prefix}kv" \
    --resource-group "${rg_name}" \
    --location  "${location}" \
    --enabled-for-deployment true \
    --enabled-for-disk-encryption true \
    --enabled-for-template-deployment true \
    --sku standard

#
# Ensure the web app's service principal has access to KeyVault
#
az keyvault set-policy --name "${prefix}kv" \
    --secret-permission get list \
    --spn "${service_principal_id}"

spring_property_name_to_keyvault_name() {
    # Azure KeyVault doesn't allow "." in names, so we need to replace the '.' by '-'
    local spring_property_name=${1}
    echo "${spring_property_name//\./-}"
}

spring_connection_string() {
    local sql_server_name=${1}
    local sql_database=${2}
    local sql_username=${3}
    local sql_password=${4}

    connection_string="jdbc:sqlserver://${sql_server_name}.database.windows.net:1433;"
    connection_string+="database=${sql_database};"
    connection_string+="user=${sql_username}@${sql_server_name};"
    connection_string+="password=${sql_password};"
    connection_string+="encrypt=true;"
    connection_string+="trustServerCertificate=false;"
    connection_string+="hostNameInCertificate=*.database.windows.net;"
    connection_string+="loginTimeout=30;"

    echo "${connection_string}"
}

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
# https://docs.microsoft.com/en-us/azure/container-registry/container-registry-tutorial-build-task
#

export TAG=springaad

az acr task create \
    --registry "${acr_name}" \
    --name taskhelloworld \
    --image $TAG:{{.Run.ID}} \
    --context https://github.com/chgeuer/spring_boot_aad_kv.git \
    --branch master \
    --file Dockerfile \
    --git-access-token $github

export acr_password="$(az acr credential show \
    --resource-group "${rg_name}" \
    --name "${acr_name}" \
    --query "passwords[?contains(name,'password2')].[value]" \
    -o tsv)"

export cloud_build_id="cb3"

az container create \
    --name myapp \
    --resource-group "${rg_name}" \
    --location  "${location}" \
    --image "${acr_name}.azurecr.io/${TAG}:${cloud_build_id}" \
    --registry-username "${acr_name}" \
    --registry-password "${acr_password}" \
    --ip-address Public \
    --dns-name-label "${prefix}aci"\
    --ports 8080 \
    --protocol TCP \
    --environment-variables \
        "AAD_TENANT_ID=${AAD_TENANT_ID}" \
        "AAD_CLIENT_ID=${AAD_CLIENT_ID}" \
        "AAD_GROUP=${AAD_GROUP}" \
        "KEYVAULT_URI=${KEYVAULT_URI}" \
    --secure-environment-variables \
        "AAD_CLIENT_SECRET=${AAD_CLIENT_SECRET}"

# docker login "${DOCKER_REGISTRY}" \
#        --username "${DOCKER_USERNAME}" \
#        --password "${DOCKER_PASSWORD}"
