#!/bin/bash

RE_PATTERN_NUMBER=^[0-9]+$


echo "########### Certbot Renew Script ###########"

if [[ -z $LOG_FILE ]]; then
    echo  "[$(date)] [ERROR] - Log file not defined."
    exit 1
fi

if [[ -z $DOCKER_COMPOSE_FILE || -f $DOCKER_COMPOSE_FILE ]]; then
    echo "[$(date)] [ERROR] - Docker-Compose not found, in '$DOCKER_COMPOSE_FILE'." >> $LOG_FILE
    exit 1
fi

if [[ -z $LETS_PATH  || -d $LETS_PATH]]; then
    echo "[$(date)] [ERROR] - Let's Encrypt path not found, in '$LETS_PATH'." >> $LOG_FILE
    exit 1
fi

if [[ -z $CERT_WORKDIR  || -d $CERT_WORKDIR]]; then
    echo "[$(date)] [ERROR] - Cert. Workdir path not found, in '$CERT_WORKDIR'." >> $LOG_FILE
    exit 1
fi

if [[ -z $FILE_NAME ]]; then
    echo "[$(date)] [ERROR] - Certificate filename not defined." >> $LOG_FILE
    exit 1
fi

if [[ -z $CERT_EMAIL ]]; then
    echo "[$(date)] [ERROR] - Email for registration not defined." >> $LOG_FILE
    exit 1
fi

if [[ -z $CERT_DOMAINS_LIST ]]; then
    echo "[$(date)] [ERROR] - Domains for registration not defined." >> $LOG_FILE
    exit 1
fi

if ! [[ $CRITICAL_PERIOD =~ $RE_PATTERN_NUMBER ]]; then
    echo "[$(date)] [ERROR] - Critical period not is a number, actualValue=$CRITICAL_PERIOD." >> $LOG_FILE
    exit 1
fi


calc_downtime_cert(){
    local _cert_date_end=$(date --date="$(openssl x509 -in $LETS_PATH/live/$WORK_DIR/$FILE_NAME -text -noout | grep 'Not After' | cut -c 25-)" +%s)
    
    CERT_DOWNTIME=$(( ($_cert_date_end - $date_today) / $second_per_day ))
}

get_domains_cert(){
    CERT_GEN_DOMAINS=($(openssl x509 -in $LETS_PATH/live/$WORK_DIR/$FILE_NAME -text -noout | grep -oP '(?<=DNS:)[^,]*' | tr "\n" " "))
}

renew_cert(){
    docker-compose -f $DOCKER_COMPOSE_PATH run --rm app \
    certonly --webroot --webroot-path=/var/www/certbot \
    -m $CERT_EMAIL -d $CERT_DOMAINS_LIST \
    --force-renewal --agree-tos
}


second_per_day=$[24*3600]
date_today=$(date -d "now" +%s)
LOG_REALTIME = ""

if ! [[ -f $LETS_PATH/live/$CERT_WORKDIR/$FILE_NAME ]]; then
    LOG_REALTIME+="'$LETS_PATH/live/$CERT_WORKDIR/$FILE_NAME' not found, creating... "
else
    calc_downtime_cert
    
    LOG_REALTIME+="'$LETS_PATH/live/$CERT_WORKDIR/$FILE_NAME' found, certificate downtime in '$CERT_DOWNTIME days'... CRITICAL_PERIOD=$CRITICAL_PERIOD, "
    
    if [[ $CERT_DOWNTIME -gt $CRITICAL_PERIOD ]]; then
        LOG_REALTIME+="nothing to do, the certificate is within the security space."
        
        echo $LOG_REALTIME >> $LOG_FILE
        
        exit 0
    fi
fi

renew_cert
calc_downtime_cert

if [[ $cert_downtime -le $CRITICAL_PERIOD ]]; then
    LOG_REALTIME+="unsuccessful renewal."
    
    echo $LOG_REALTIME >> $LOG_FILE
    
    exit 1
fi

get_domains_cert
CERT_GEN_DOMAINS

DOMAINS_LIST_TMP=$(echo $CERT_DOMAINS_LIST | tr "," " ")

UNVERIFIED_DOMAINS=$(
    for domain in ${DOMAINS_LIST_TMP[@]}; do
        [[ $domain =~ "$CERT_GEN_DOMAINS" ]] || echo $domain
    done
)

if [[ -z $unverified_domains ]]; then
    echo "  Ok.: successful renewal"
    echo "     : Days Remaining: $cert_downtime"
else
    echo "  Ok (Partial).: successful renewal"
    echo "  - Days Remaining: $cert_downtime"
    echo "  - Unverified Domains: $unverified_domains"
fi


exit 0
