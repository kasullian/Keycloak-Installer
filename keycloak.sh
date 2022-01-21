export DOMAIN_SUBDOMAIN=auth.domain.com # for example mykeycloak.com or keycloak.mydomain.com
export KEYCLOAK_SSL_ALIAS=domain # the alias for your SSL certificate which can be anything but avoid weird characters
export KEYCLOAK_SSL_PASSWORD=password123 # the password for your SSL certificate, again avoid weird characters
export KEYSTORE_PASSWORD=password123 # this will be the password to access the Java keystore where your certificate will live, should be the same as your SSL_PASSWORD
export KEYCLOAK_PASSWORD=password