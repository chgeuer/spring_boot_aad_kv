#!/bin/bash

export TAG=springaad

docker build \
    --tag "${TAG}" \
    .

docker run \
    -e "AAD_TENANT_ID=${AAD_TENANT_ID}" \
    -e "AAD_CLIENT_ID=${AAD_CLIENT_ID}" \
    -e "AAD_CLIENT_SECRET=${AAD_CLIENT_SECRET}" \
    -e "AAD_GROUP=${AAD_GROUP}" \
    -e "KEYVAULT_URI=${KEYVAULT_URI}" \
    -p 8080:8080/tcp \
    --interactive --tty --rm \
    "${TAG}"


#     --entrypoint /bin/bash \