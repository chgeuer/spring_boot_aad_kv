#!/bin/bash

#
# Which AAD Tenant is the web app living in?
#
export AAD_TENANT_ID="chgeuerfte.onmicrosoft.com"

#
# Which Data Center
#
export location="westeurope"

#
# Name of the Azure resource group
#
export rg_name="spring1"

#
# The prefix is used for naming various resource
#
export prefix="springchgp"

echo "Using Azure AD tenant ${AAD_TENANT_ID}, deploying to resource group ${rg_name} in ${location}"

#
# The Azure AD group which users must be in, to access the web app.
#
export AAD_GROUP="christian"

#
# Various names for resources
#
export sql_server_name="${prefix}sql"
export sql_database="${prefix}db"
export sql_username="${prefix}user"
export acr_name="${prefix}acr"
export aci_name="${prefix}aci"
export keyvault_name="${prefix}kv"
export keyvault_url="https://${keyvault_name}.vault.azure.net/"
export public_web_app_hostname="${aci_name}.${location}.azurecontainer.io"

export TAG=springaad
export acr_build_task_name="build-${TAG}-task"




export sql_password="$(cat .passwords/.${rg_name}-${prefix}-sql_password)"
export service_principal_pass="$(cat .passwords/.${rg_name}-${prefix}-service_principal_pass)"
export service_principal_application_id="$(cat .passwords/.${rg_name}-${prefix}-service_principal_application_id)"
export service_principal_object_id="$(cat .passwords/.${rg_name}-${prefix}-service_principal_object_id)"
