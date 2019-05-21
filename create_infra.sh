#!/bin/bash

#
# Check https://github.com/microsoft/azure-spring-boot/tree/master/azure-spring-boot-samples/azure-keyvault-secrets-spring-boot-sample
#
export rg_name="spring"
export prefix="chgeuerspring"
export location="westeurope"
export sql_azure_connection_string="jdbc:mysql://somedb-in-azure:3306/moviedb"

export keyvault_name="${prefix}kv"
export service_principal_id="${AAD_CLIENT_ID}"
#
# Azure KeyVault doesn't allow "." in names, so we need to replace the '.' by '-'
#
export spring_property="spring.datasource.url"
export spring_property_name_for_keyvault="${spring_property//\./-}"


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

az keyvault secret set --vault-name "${keyvault_name}" \
    --name "${spring_property_name_for_keyvault}" \
    --value "${sql_azure_connection_string}"

# az keyvault secret show --vault-name "${keyvault_name}" \
#     --name "${spring_property_name_for_keyvault}"
