#!/bin/bash

apiVersion="2018-02-01"

curl --request GET \
    --silent \
    "http://169.254.169.254/metadata/instance?api-version=${apiVersion}"
