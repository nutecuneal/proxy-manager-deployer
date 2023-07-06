#!/bin/bash

RE_PATTERN_NUMBER=^[0-9]+$

SECONDS_PER_DAY=$(( 24*3600 ))
DATE_TODAY=$(date -d "now" +%s)

log_prefix=
log_realtime=


calc_downtime_certificate(){
    local cert_date_end=$(date --date="$(openssl x509 -in $LETS_PATH/live/$CERT_WORKDIR/$FILE_NAME -text -noout | grep 'Not After' | cut -c 25-)" +%s)
    
    cert_downtime=$(( ($cert_date_end - $DATE_TODAY) / $SECONDS_PER_DAY ))
}

get_all_domains_from_certificate(){
    cert_all_domains=($(openssl x509 -in $LETS_PATH/live/$WORK_DIR/$FILE_NAME -text -noout | grep -oP '(?<=DNS:)[^,]*' | tr "\n" " "))
}

renew_certificate(){
    docker-compose -f $DOCKER_COMPOSE_PATH run --rm app \
    certonly --webroot --webroot-path=/var/www/certbot \
    -m $CERT_EMAIL -d $CERT_DOMAINS_FOR_REGIST \
    --force-renewal --agree-tos
}

print_log(){
    echo "$log_prefix - $log_realtime"
}


if [[ -z $DOCKER_COMPOSE_FILE || ! -f $DOCKER_COMPOSE_FILE ]]; then
    log_prefix=$(echo "[$(date)] [ERROR]")
    log_realtime+="Docker-Compose not found, in '$DOCKER_COMPOSE_FILE'."
    
    print_log
    
    exit 1
fi

if [[ -z $LETS_PATH  || ! -d $LETS_PATH ]]; then
    log_prefix=$(echo "[$(date)] [ERROR]")
    log_realtime+="Let's Encrypt path not found, in '$LETS_PATH'."
    
    print_log
    
    exit 1
fi

if [[ -z $CERT_WORKDIR ]]; then
    log_prefix=$(echo "[$(date)] [ERROR]")
    log_realtime+="Cert. workdir not defined."
    
    print_log
    
    exit 1
fi

if [[ -z $FILE_NAME ]]; then
    log_prefix=$(echo "[$(date)] [ERROR]")
    log_realtime+="Certificate filename not defined."
    
    print_log
    
    exit 1
fi

if [[ -z $CERT_EMAIL ]]; then
    log_prefix=$(echo "[$(date)] [ERROR]")
    log_realtime+="Email for registration not defined."
    
    print_log
    
    exit 1
fi

if [[ -z $CERT_DOMAINS_FOR_REGIST ]]; then
    log_prefix=$(echo "[$(date)] [ERROR]")
    log_realtime+="Domains for registration not defined."
    
    print_log
    
    exit 1
fi

if ! [[ $CRITICAL_PERIOD =~ $RE_PATTERN_NUMBER ]]; then
    log_prefix=$(echo "[$(date)] [ERROR]")
    log_realtime+="Critical period not is a number, actual=$CRITICAL_PERIOD."
    
    print_log
    
    exit 1
fi


if [[ ! -f $LETS_PATH/live/$CERT_WORKDIR/$FILE_NAME ]]; then
    log_realtime+="'$LETS_PATH/live/$CERT_WORKDIR/$FILE_NAME' not found, creating... "
else
    calc_downtime_certificate
    
    log_realtime+="'$LETS_PATH/live/$CERT_WORKDIR/$FILE_NAME' found, certificate downtime in '$cert_downtime days'... CRITICAL_PERIOD=$CRITICAL_PERIOD, "
    
    if [[ $cert_downtime -gt $CRITICAL_PERIOD ]]; then
        log_prefix=$(echo "[$(date)] [OK]")
        log_realtime+="nothing to do, the certificate is within the security space."
        
        print_log
        
        exit 0
    fi
fi

renew_cert

calc_downtime_certificate

if [[ $cert_downtime -le $CRITICAL_PERIOD ]]; then
    log_prefix=$(echo "[$(date)] [ERROR]")
    log_realtime+="unsuccessful renewal."
    
    print_log
    
    exit 1
fi

get_all_domains_from_certificate

all_domains_for_renewal=$(echo $CERT_DOMAINS_FOR_REGIST | tr "," " ")

unverified_domains=$(
    for domain in ${all_domains_for_renewal[@]}; do
        [[ $domain =~ "$cert_all_domains" ]] || echo $domain
    done
)

if [[ -z $unverified_domains ]]; then
    log_prefix=$(echo "[$(date)] [OK]")
    log_realtime+="successful renewal."
else
    log_prefix=$(echo "[$(date)] [OK (PARTIAL)]")
    log_realtime+="successful renewal (partial), unverified domains ($unverified_domains). "
fi

log_realtime+="Days Remaining: $cert_downtime."

if  [[ ! -z $SCRIPT_POST_RENEW_FILE && -f $SCRIPT_POST_RENEW_FILE  ]]; then
    log_realtime+=$(echo " Running '$SCRIPT_POST_RENEW_FILE'... $($SCRIPT_POST_RENEW_FILE && echo "finished" || echo "fail").")
fi

print_log
