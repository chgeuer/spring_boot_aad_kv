#!/bin/bash

apiVersion="2018-02-01"

curl --request GET \
    --silent \
    -H Metadata:true \
    "http://169.254.169.254/metadata/instance/compute?api-version=${apiVersion}"



