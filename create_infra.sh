#!/bin/bash

#
# Check https://github.com/microsoft/azure-spring-boot/tree/master/azure-spring-boot-samples/azure-keyvault-secrets-spring-boot-sample
#
export rg_name="spring"
export prefix="chgeuerspring"
export location="westeurope"

export keyvault_name="${prefix}kv"
export service_principal_id="${AAD_CLIENT_ID}"
#
# Azure KeyVault doesn't allow "." in names, so we need to replace the '.' by '-'
#
export spring_url_key="spring.datasource.url"
export spring_url_value="jdbc:sqlserver://wingtiptoyssql.database.windows.net:1433;database=wingtiptoys;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"

export spring_username_key="spring.datasource.username"
export spring_username_value="wingtiptoysuser@wingtiptoyssql"

export spring_password_key="spring.datasource.password"
export spring_password_value="supersecret123.-"


# az keyvault create --name "${prefix}kv" \
#     --resource-group "${rg_name}" \
#     --location  "${location}" \
#     --enabled-for-deployment true \
#     --enabled-for-disk-encryption true \
#     --enabled-for-template-deployment true \
#     --sku standard

# az keyvault set-policy --name "${prefix}kv" \
#     --secret-permission get list \
#     --spn "${service_principal_id}"

az keyvault secret set --vault-name "${keyvault_name}" --name "${spring_url_key//\./-}" --value "${spring_url_value}"
az keyvault secret set --vault-name "${keyvault_name}" --name "${spring_username_key//\./-}" --value "${spring_username_value}"
az keyvault secret set --vault-name "${keyvault_name}" --name "${spring_password_key//\./-}" --value "${spring_password_value}"

# az keyvault secret show --vault-name "${keyvault_name}" \
#     --name "${spring_property_name_for_keyvault}"
