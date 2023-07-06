#!/bin/bash

# Docker-Compose (file) path.
export DOCKER_COMPOSE_FILE=./certbot.docker-compose.yml

# Let's Encrypt path.
export LETS_PATH=$(pwd)/lets

# Name is used by Certbot for housekeeping and in file paths. Domain/"cert-name"
export CERT_WORKDIR=cert-name

# Certificate filename, usually "fullchain.pem"
export FILE_NAME=fullchain.pem

# Email used for registration.
export CERT_EMAIL=example@email.com

# List of domains for registration (commam separated).
export CERT_DOMAINS_FOR_REGIST=example.domain1[[,example.domain2]...]

# The certificate will be updated if its lifetime is less than or equal this value.
export CRITICAL_PERIOD=15a

# Script run: successful post renew.
#export SCRIPT_POST_RENEW_FILE=certbot-post-renew.sh

./certbot-renew.sh


