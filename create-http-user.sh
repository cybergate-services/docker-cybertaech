#!/bin/bash -xe
source ./.env
mkdir -p ./shared
echo $(htpasswd -nb $HTTP_USERNAME $HTTP_PASSWORD) > shared/.htpasswd
