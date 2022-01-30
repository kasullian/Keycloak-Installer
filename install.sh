#!/bin/bash

#remove previous keycloak installation
rm -r /opt/keycloak
systemctl stop keycloak
systemctl disable keycloak

#install necessary tools
apt-get update
apt-get install unzip -y
apt-get install default-jdk -y
sudo apt install ufw -y

#copy template service into systemd service directory
cp keycloak.service /etc/systemd/system/keycloak.service

#copy required config files for ssl & auto renewal
cp standalone.xml /opt; cp post-hook.sh /opt; cp pre-hook.sh /opt; cp new-cert-to-keystore.sh /opt

#copy env variables into /etc/profile.d
cp keycloak.sh /etc/profile.d

#import env vars
source /etc/profile

#download and unzip targeted keycloak version, todo: write configuration into standalone.xml
cd /opt
KEYCLOAK_VERSION=16.1.0
wget https://github.com/keycloak/keycloak/releases/download/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.zip
unzip keycloak-$KEYCLOAK_VERSION.zip
rm keycloak-$KEYCLOAK_VERSION.zip
mv keycloak-$KEYCLOAK_VERSION /opt/keycloak
#modify standalone.xml to include your alias & passwords
sed -i 's/KEYCLOAK_SSL_PASSWORD/'"$KEYCLOAK_SSL_PASSWORD"'/g' standalone.xml
mv standalone.xml /opt/keycloak/standalone/configuration

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

#move lets encrypt hook scripts
mv post-hook.sh /etc/letsencrypt/renewal-hooks/post; chmod +x /etc/letsencrypt/renewal-hooks/post/post-hook.sh
mv pre-hook.sh /etc/letsencrypt/renewal-hooks/pre; chmod +x /etc/letsencrypt/renewal-hooks/pre/pre-hook.sh
mv new-cert-to-keystore.sh /etc/letsencrypt/renewal-hooks/deploy; chmod +x /etc/letsencrypt/renewal-hooks/deploy/new-cert-to-keystore.sh

#retrieve cert from lets encrypt
ufw allow 80/tcp
certbot certonly --standalone --preferred-challenges http -d $DOMAIN_SUBDOMAIN
ufw deny 80/tcp 

openssl pkcs12 -export -in /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/fullchain.pem -inkey /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/privkey.pem -out /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/pkcs.p12 -name $KEYCLOAK_SSL_ALIAS -passout pass:$KEYCLOAK_SSL_PASSWORD

#convert pkcs12 into jks format and export to keycloak config directory
cd /opt/keycloak/standalone/configuration
keytool -keystore keycloak.jks -genkey -alias key_to_be_deleted -storepass $KEYCLOAK_SSL_PASSWORD
keytool -delete -noprompt -alias key_to_be_deleted -keystore keycloak.jks -storepass $KEYCLOAK_SSL_PASSWORD
keytool -importkeystore -deststorepass $KEYCLOAK_SSL_PASSWORD -destkeypass $KEYCLOAK_SSL_PASSWORD -destkeystore keycloak.jks -srckeystore /etc/letsencrypt/live/$DOMAIN_SUBDOMAIN/pkcs.p12 -srcstoretype PKCS12 -srcstorepass $KEYCLOAK_SSL_PASSWORD -alias $KEYCLOAK_SSL_ALIAS
keytool -list -v -keystore keycloak.jks -storepass $KEYCLOAK_SSL_PASSWORD

cd /opt/keycloak/bin
chmod +x add-user-keycloak.sh
bash add-user-keycloak.sh -r master -u admin -p $KEYCLOAK_PASSWORD

#start keycloak service
systemctl daemon-reload
systemctl enable keycloak
systemctl start keycloak