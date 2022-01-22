# Keycloak Installer

Keycloak Installer is a set of scripts that handles the installation and configuration of a keycloak standalone server.

## Configuration
* Replace all values within keycloak.sh with your desired domain, passwords, and alias

## Installation
```bash
# Clone the repo
git clone https://github.com/kasullian/Keycloak-Installer

# Install keycloak
sudo chmod +x installer.sh
sudo ./installer.sh
```

## Test SSL renewel through certbot
```
sudo certbot renew --dry-run
```
