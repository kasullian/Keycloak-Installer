#!/bin/bash

#remove previous keycloak instance
rm -r /opt/keycloak
systemctl stop keycloak
systemctl disable keycloak

#install necessary tools
apt-get update
apt-get install unzip
apt-get install default-jdk -y

#copy template service into systemd service directory
cp keycloak.service /etc/systemd/system/keycloak.service

#copy required config files for ssl & auto renewal
cp standalone.xml /opt; cp new-cert-to-keystore.sh /opt; cp post-hook.sh /opt; cp pre-hook.sh /opt

#copy env variables into /etc/profile.d
cp keycloak.sh /etc/profile.d

#import env vars
source /etc/profile

#download and unzip targeted keycloak version, todo: write configuration into standalone.xml
cd /opt
wget https://github.com/keycloak/keycloak/releases/download/15.0.2/keycloak-15.0.2.zip
unzip keycloak-15.0.2.zip
rm keycloak-15.0.2.zip
mv keycloak-15.0.2 /opt/keycloak
#modify standalone.xml to include your alias & passwords
sed -i 's/KEYSTORE_PASSWORD/'"$KEYSTORE_PASSWORD"'/g' standalone.xml
sed -i 's/KEYCLOAK_SSL_ALIAS/'"$KEYCLOAK_SSL_ALIAS"'/g' standalone.xml
sed -i 's/KEYCLOAK_SSL_PASSWORD/'"$KEYCLOAK_SSL_PASSWORD"'/g' standalone.xml
mv standalone.xml /opt/keycloak/standalone/configuration
certbot certonly --standalone --preferred-challenges http -d $DOMAIN_SUBDOMAIN

#create keycloak user and assign ownership
groupadd keycloak
useradd -r -g keycloak -d /opt/keycloak -s /sbin/nologin keycloak
chown -R keycloak:keycloak keycloak

#copy template config & launcher, then modify
rm -r /etc/keycloak; mkdir /etc/keycloak
cp /opt/keycloak/docs/contrib/scripts/systemd/wildfly.conf /etc/keycloak/keycloak.conf
cp /opt/keycloak/docs/contrib/scripts/systemd/launch.sh /opt/keycloak/bin/
sed -i 's/wildfly/keycloak/g' /opt/keycloak/bin/launch.sh
chown keycloak:keycloak /opt/keycloak/bin/launch.sh

#configure ssl
snap install core
snap refresh core
snap remove core20
snap install core20
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

#retrieve cert from lets encrypt
ufw allow 80/tcp
certbot certonly --standalone --preferred-challenges http -d $DOMAIN_SUBDOMAIN
ufw deny 80/tcp 
sudo openssl pkcs12 -export -in /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/fullchain.pem -inkey /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/privkey.pem -out /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/pkcs.p12 -name $KEYCLOAK_SSL_ALIAS -passout pass:$KEYCLOAK_SSL_PASSWORD

#move lets encrypt hook scripts
mv new-cert-to-keystore.sh /etc/letsencrypt/renewal-hooks/deploy; chmod +x /etc/letsencrypt/renewal-hooks/deploy/new-cert-to-keystore.sh
mv post-hook.sh /etc/letsencrypt/renewal-hooks/post; chmod +x /etc/letsencrypt/renewal-hooks/post/post-hook.sh
mv pre-hook.sh /etc/letsencrypt/renewal-hooks/pre; chmod +x /etc/letsencrypt/renewal-hooks/pre/pre-hook.sh

#convert pkcs12 into jks format and export to keycloak config directory
cd /opt/keycloak/standalone/configuration
keytool -keystore keycloak.jks -genkey -alias key_to_be_deleted
keytool -list -v -keystore keycloak.jks -storepass $KEYSTORE_PASSWORD
keytool -delete -noprompt -alias key_to_be_deleted -keystore keycloak.jks -storepass $KEYSTORE_PASSWORD
keytool -list -v -keystore keycloak.jks -storepass $KEYSTORE_PASSWORD
keytool -importkeystore -deststorepass $KEYSTORE_PASSWORD -destkeypass $KEYCLOAK_SSL_PASSWORD -destkeystore keycloak.jks -srckeystore /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/pkcs.p12 -srcstoretype PKCS12 -srcstorepass $KEYCLOAK_SSL_PASSWORD -alias $KEYCLOAK_SSL_ALIAS

cd /opt/keycloak/bin
chmod +x add-user-keycloak.sh
bash add-user-keycloak.sh -r master -u admin -p $KEYCLOAK_PASSWORD

#start keycloak service
systemctl daemon-reload
systemctl enable keycloak
systemctl start keycloak