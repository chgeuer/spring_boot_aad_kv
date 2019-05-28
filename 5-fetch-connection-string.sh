#!/bin/bash

service_principal_application_id="$(cat .passwords/.${rg_name}-${prefix}-service_principal_application_id)"
service_principal_pass="$(cat .passwords/.${rg_name}-${prefix}-service_principal_pass)"

access_token="$(curl \
    --silent \
    --request POST \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_id=${service_principal_application_id}" \
    --data-urlencode "client_secret=${service_principal_pass}" \
    --data-urlencode "resource=https://vault.azure.net" \
    "https://login.microsoftonline.com/${AAD_TENANT_ID}/oauth2/token" | \
        jq -r ".access_token")"

spring_property_name_to_keyvault_name() {
    # Azure KeyVault doesn't allow "." in names, so we need to replace the '.' by '-'
    local spring_property_name=${1}
    echo "${spring_property_name//\./-}"
}

secret_name="$(spring_property_name_to_keyvault_name 'spring.datasource.url')"

apiVersion="7.0"

secretVersion="$(curl -s -H "Authorization: Bearer ${access_token}" \
    "https://${keyvault_name}.vault.azure.net/secrets/${secret_name}/versions?api-version=${apiVersion}" | \
    jq -r ".value | sort_by(.attributes.created) | .[-1].id")"

secret="$(curl -s -H "Authorization: Bearer ${access_token}" \
    "${secretVersion}?api-version=${apiVersion}" | \
    jq -r ".value" )"

echo "${secret}"
