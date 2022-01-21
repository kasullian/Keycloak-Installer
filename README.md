# Keycloak Installer

Keycloak Installer is a set of scripts that handles the installation and configuration of keycloak.

## Installation

Clone the repository to your desired location.

```bash
git clone https://gitlab.com/Kasull/keycloak-installer.git
```

## Configuration
* Replace all values within keycloak.sh with your desired domain, passwords, and alias
* Modify line #36 in standalone xml to contain your desired KEYSTORE_PASSWORD, KEYCLOAK_SSL_ALIAS, and KEYCLOAK_SSL_PASSWORD (temporary)

## Usage

```bash
sudo chmod +x installer.sh
./installer.sh
```