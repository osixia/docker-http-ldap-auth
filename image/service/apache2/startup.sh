#!/bin/bash -e

# set -x (bash debug) if log level is trace
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/log-helper
log-helper level eq trace && set -x

ln -sf "${CONTAINER_SERVICE_DIR}/apache2/assets/conf-available/ldap-auth.conf" /etc/apache2/conf-available/ldap-auth.conf
ln -sf "${CONTAINER_SERVICE_DIR}/apache2/assets/sites-available/ldap-auth.conf" /etc/apache2/sites-available/ldap-auth.conf

a2enconf ldap-auth
a2ensite ldap-auth

FIRST_START_DONE="${CONTAINER_STATE_DIR}/docker-http-ldap-auth-first-start-done"
# container first start
if [ ! -e "${FIRST_START_DONE}" ]; then
    
    # check certificat and key or create it
    ssl-helper "${HTTP_LDAP_AUTH_SSL_HELPER_PREFIX}" "${CONTAINER_SERVICE_DIR}/apache2/assets/certs/${HTTP_LDAP_AUTH_HTTPS_CRT_FILENAME}" "${CONTAINER_SERVICE_DIR}/apache2/assets/certs/${HTTP_LDAP_AUTH_HTTPS_KEY_FILENAME}" "${CONTAINER_SERVICE_DIR}/apache2/assets/certs/${HTTP_LDAP_AUTH_HTTPS_CA_CRT_FILENAME}"
    
    # add CA certificat config if CA cert exists
    if [ -e "${CONTAINER_SERVICE_DIR}/apache2/assets/certs/$HTTP_LDAP_AUTH_HTTPS_CA_CRT_FILENAME" ]; then
        sed -i "s/#SSLCACertificateFile/SSLCACertificateFile/g" "${CONTAINER_SERVICE_DIR}/apache2/assets/sites-available/ldap-auth.conf"
    fi
    
    # locations config
    for location in $(complex-bash-env iterate HTTP_LDAP_AUTH_LOCATIONS)
    do
        
        # append location config to apache site config
        sed -i "/{{ LOCATIONS }}/r ${CONTAINER_SERVICE_DIR}/apache2/assets/sites-available/ldap-auth-location.conf.tmpl" "${CONTAINER_SERVICE_DIR}/apache2/assets/sites-available/ldap-auth.conf"
        
        if [ "$(complex-bash-env isRow "${!location}")" = true ]; then
            location_name=$(complex-bash-env getRowKey "${!location}")
            infos=$(complex-bash-env getRowValueVarName "${!location}")
            
            sed -i "s|{{ LOCATION_NAME }}|${location_name}|g" "${CONTAINER_SERVICE_DIR}/apache2/assets/sites-available/ldap-auth.conf"
            
            for info in $(complex-bash-env iterate "$infos")
            do
                if [ "$(complex-bash-env isRow "${!info}")" = true ]; then
                    config_key=$(complex-bash-env getRowKey "${!info}")
                    onfig_value=$(complex-bash-env getRowValue "${!info}")
                    
                    sed -i "s|{{ LOCATION_${config_key^^} }}|${onfig_value}|g" "${CONTAINER_SERVICE_DIR}/apache2/assets/sites-available/ldap-auth.conf"
                else
                    log-helper error "HTTP_LDAP_AUTH_LOCATIONS ${location_name} config is not valid"
                    exit 1
                fi
            done
        else
            log-helper error "HTTP_LDAP_AUTH_LOCATIONS is not valid"
            exit 1
        fi
    done
    
    # delete locations tags
    sed -i "/{{ LOCATIONS }}/d" "${CONTAINER_SERVICE_DIR}/apache2/assets/sites-available/ldap-auth.conf"
    
    touch "${FIRST_START_DONE}"
fi
