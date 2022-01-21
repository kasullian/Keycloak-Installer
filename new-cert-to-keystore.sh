#!/bin/bash

#import env vars
source /etc/profile

# Stop Keycloak
systemctl stop keycloak

# Convert the private key and certificate to a PKCS12 file
openssl pkcs12 -export -in /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/fullchain.pem -inkey /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/privkey.pem -out /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/pkcs.p12 -name $KEYCLOAK_SSL_ALIAS -passout pass:$KEYCLOAK_SSL_PASSWORD

# Remove the old certificate from our keystore
keytool -delete -noprompt -alias $KEYCLOAK_SSL_ALIAS -keystore /opt/keycloak/current/standalone/configuration/keycloak.jks -storepass $KEYSTORE_PASSWORD

# Import the new certificate to our keystore
keytool -importkeystore -deststorepass $KEYSTORE_PASSWORD -destkeypass $KEYCLOAK_SSL_PASSWORD -destkeystore /opt/keycloak/standalone/configuration/keycloak.jks -srckeystore /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/pkcs.p12 -srcstoretype PKCS12 -srcstorepass $KEYCLOAK_SSL_PASSWORD -alias $KEYCLOAK_SSL_ALIAS

# Start Keycloak
systemctl start keycloak