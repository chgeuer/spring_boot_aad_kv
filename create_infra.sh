#!/bin/bash

export rg_name="spring"
export prefix="chgeuerspring"
export location="westeurope"

export sql_server_name="${prefix}sql"
export sql_database="${prefix}db"
export sql_username="${prefix}user"
export sql_password="$(openssl rand 14 -base64)"

export keyvault_name="${prefix}kv"
export service_principal_id="${AAD_CLIENT_ID}"

az sql server create \
    --name "${sql_server_name}" \
    --resource-group "${rg_name}" \
    --location  "${location}" \
    --admin-user "${sql_username}" \
    --admin-password "${sql_password}"

#
# For test purposes, open up SQL Azure's firewall
#
export startip=0.0.0.0
export endip=223.255.255.255
az sql server firewall-rule create \
    --name FullInternetCanAccess \
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

#
# Azure KeyVault doesn't allow "." in names, so we need to replace the '.' by '-'
#
export spring_url_key="spring.datasource.url"
export spring_url_value="jdbc:sqlserver://${sql_server_name}.database.windows.net:1433;database=${sql_database};user=${sql_username}@${sql_server_name};password=${sql_password};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"

az keyvault secret set \
    --vault-name "${keyvault_name}" \
    --name "${spring_url_key//\./-}" \
    --value "${spring_url_value}"
