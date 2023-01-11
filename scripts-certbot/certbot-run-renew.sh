#!/bin/bash

# Docker-Compose (file) path.
export DOCKER_COMPOSE_PATH=./certbot.docker-compose.yml

# Let's Encrypt path.
export LETS_PATH=$(pwd)/lets

# Name is used by Certbot for housekeeping and in file paths. Domain/"cert-name"
export WORK_DIR=cert-name

# Certificate filename, usually "fullchain.pem"
export FILE_NAME=fullchain.pem

# Email used for registration.
export CERT_EMAIL=example@email.com

# List of domains for registration (comma separated).
export CERT_DOMAINS_LIST=example.domain1[[,example.domain2]...]

# The certificate will be updated if its lifetime is less than or equal this value.
export CRITICAL_PERIOD=30

# Script run: successful post renew.
#export SCRIPT_POST_RENEW_FILENAME=certbot-post-renew.sh



if [[ -z $SCRIPT_POST_RENEW_FILENAME ]]; then
    ./certbot-renew.sh
else
    ./certbot-renew.sh && \
    echo "" && echo "" && \
    echo "++++++ RUN POST-RENEW ++++++" && \
    ./$SCRIPT_POST_RENEW_FILENAME
fi


