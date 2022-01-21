# Keycloak Installer

Keycloak Installer is a set of scripts that handles the installation and configuration of keycloak.

## Installation

Clone the repository to your desired location.

```bash
git clone https://gitlab.com/Kasull/keycloak-installer.git
```

## Configuration
* Replace all values within keycloak.sh with your desired domain, passwords, and alias
* Modify line #36 in the included standalone.xml, replace KEYSTORE_PASSWORD, KEYCLOAK_SSL_ALIAS, and KEYCLOAK_SSL_PASSWORD with the values from your keycloak.sh (temporary)

## Usage

```bash
sudo chmod +x installer.sh
sudo ./installer.sh
```
