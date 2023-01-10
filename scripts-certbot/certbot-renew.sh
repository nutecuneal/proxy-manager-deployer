#!/bin/bash

echo "########### Certbot Renew Script ###########"

if [[ -z $DOCKER_COMPOSE_PATH ]]; then
    echo "|"
    echo "|+- Status:"
    echo "  Failure.: Docker-Compose path not defined."
    exit 1
fi

if [[ -z $LETS_PATH ]]; then
    echo "|"
    echo "|+- Status:"
    echo "  Failure.: Let's Encrypt path not defined."
    exit 1
fi

if [[ -z $LETS_WEB_ROOT_PATH ]]; then
    echo "|"
    echo "|+- Status:"
    echo "  Failure.: Let's Encrypt webroot path not defined."
    exit 1
fi

if [[ -z $WORK_DIR ]]; then
    echo "|"
    echo "|+- Status:"
    echo "  Failure.: work dir. not defined."
    exit 1
fi

if [[ -z $FILE_NAME ]]; then
    echo "|"
    echo "|+- Status:"
    echo "  Failure.: certificate filename not defined."
    exit 1
fi

if [[ -z $CERT_EMAIL ]]; then
    echo "|"
    echo "|+- Status:"
    echo "  Failure.: Email for registration not defined."
    exit 1
fi

if [[ -z $CERT_DOMAINS_LIST ]]; then
    echo "|"
    echo "|+- Status:"
    echo "  Failure.: domains for registration not defined."
    exit 1
fi

if [[ -z $CRITICAL_PERIOD ]]; then
    echo "|"
    echo "|+- Status:"
    echo "  Failure.: critical period not defined."
    exit 1
fi



second_per_day=$[24*3600]
date_today=$(date -d "now" +%s)

fun_calc_downtime_cert(){
    local _cert_date_end=$(date --date="$(openssl x509 -in $LETS_PATH/live/$WORK_DIR/$FILE_NAME -text -nouot | grep 'Not After' | cut -c 25-)" +%s)
    
    cert_downtime=$[($_cert_date_end - $date_today) / $second_per_day]
}

fun_get_domains_cert(){
    cert_domains=$(openssl x509 -in $LETS_PATH/live/$WORK_DIR/$FILE_NAME -text -noout | grep -oP '(?<=DNS:)[^,]*' | tr "\n" " ")
}

fun_renew_cert(){
    docker-compose -f certbot.docker-compose.yml run --rm app \
    certonly --webroot --webroot-path=$LETS_WEB_ROOT_PATH \
    -m $CERT_EMAIL -d $CERT_DOMAINS_LIST \
    --agree-tos
}

fun_main(){
    
    echo "|-+ Work Dir.: $WORK_DIR"
    echo "|-+ Filename.: $FILE_NAME"
    echo "|-+ Date.: $(date)"
    echo "|"
    echo "|-+ Conf. Domain.:"
    echo "  $CERT_DOMAINS_LIST"
    echo "|-+ Conf. Critical Period.:"
    echo "  downtime <= $CRITICAL_PERIOD"
    echo "|"
    echo "|+- Status:"
    echo "|"
    
    if [[ !(-e $LETS_PATH/live/$WORK_DIR/$FILE_NAME) ]]; then
        echo "  Failure.: file not found!"
        exit 1
    fi
    
    fun_calc_downtime_cert
    
    if [[ $cert_downtime -gt $CRITICAL_PERIOD ]]; then
        echo "  Ok.: Nothing to do, the certificate is within the security space."
        echo "     : Days Remaining: $cert_downtime"
        exit 0
    fi
    
    fun_renew_cert
    
    fun_calc_downtime_cert
    
    if [[ $cert_downtime -le $CRITICAL_PERIOD ]]; then
        echo "  Failed.: unsuccessful renewal."
        echo "         : Days Remaining: $cert_downtime"
        exit 1
    fi
    
    fun_get_domains_cert
    
    tmp_domains="$CERT_DOMAINS_LIST,"
    
    tmp_domains_arr=()
    while [[ $tmp_domains ]]; do
        tmp_domains_arr+=( "${tmp_domains%%","*}" )
        tmp_domains=${tmp_domains#*","}
    done
    
    unverified_domains=$(
        for domain in ${tmp_domains_arr[@]}; do
            [[ "$cert_domains" =~ "$domain" ]] || echo $domain
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
    
}

fun_main

exit 0
