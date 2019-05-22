#!/bin/sh
echo "spring.profiles.active=$PROFILE" > application.properties
exec $@
