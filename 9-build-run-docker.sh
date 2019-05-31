#!/bin/bash

export TAG=springaad

docker build \
    --tag "${TAG}" \
    .

docker run \
    -e "AAD_TENANT_ID=${AAD_TENANT_ID}" \
    -e "AAD_CLIENT_ID=${service_principal_application_id}" \
    -e "AAD_CLIENT_SECRET=${service_principal_pass}" \
    -e "AAD_GROUP=${AAD_GROUP}" \
    -e "KEYVAULT_URI=${keyvault_url}" \
    -p 8080:8080/tcp \
    --interactive --tty --rm \
    "${TAG}"


#     --entrypoint /bin/bash \