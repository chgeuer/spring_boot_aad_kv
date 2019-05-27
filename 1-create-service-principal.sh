#!/bin/bash

#
# Create a bunch of random passwords
#
mkdir .passwords
export sql_password="$(openssl rand 14 -base64)"
echo "${sql_password}" > ".passwords/.${rg_name}-${prefix}-sql_password"
sql_password="$(cat .passwords/.${rg_name}-${prefix}-sql_password)"


# export service_principal_pass="${AAD_CLIENT_ID}"
export service_principal_pass="$(openssl rand 14 -base64)"
echo "${service_principal_pass}" > ".passwords/.${rg_name}-${prefix}-service_principal_pass"
service_principal_pass="$(cat .passwords/.${rg_name}-${prefix}-service_principal_pass)"

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
        "https://biseviewer.sap.corp/login/oauth2/code/azure" \
    --required-resource-accesses @manifest.json \
    --query "appId" -o tsv)"
echo "Application ID: ${service_principal_id}"
echo "${service_principal_id}" > ".passwords/.${rg_name}-${prefix}-service_principal_id"
service_principal_id="$(cat .passwords/.${rg_name}-${prefix}-service_principal_id)"

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

# az ad app permission add \
#     --id "${service_principal_id}" \
#     --api "${aadGraphAPI}" \
#     --api-permissions "${signInAndReadUserProfile}=Scope"

