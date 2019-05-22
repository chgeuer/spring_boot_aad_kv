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
export service_principal_id="${AAD_CLIENT_ID}"

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
