#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root (sudo)"
    exit 1
fi

# Define colors and safer character representations
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Use simpler symbols that work across most terminals
CHECKMARK='✓'
INFO='i'
ERROR='✗'
GEAR='*'
LOCK='+'
ROCKET='>'
GLOBE='@'

# Check if terminal supports Unicode emojis
if [ -t 1 ] && [ "$(locale charmap 2>/dev/null)" = "UTF-8" ]; then
    # Try to use emoji if terminal supports it
    tput sc
    echo -e '\xF0\x9F\x94\x92' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        CHECKMARK='\xE2\x9C\x94'
        INFO='\xE2\x84\xB9'
        ERROR='\xE2\x9C\x96'
        GEAR='\xF0\x9F\x94\xA7'
        LOCK='\xF0\x9F\x94\x92'
        ROCKET='\xF0\x9F\x9A\x80'
        GLOBE='\xF0\x9F\x8C\x8D'
    fi
    tput rc
fi

print_message() {
    local message=$1
    local color=$2
    local emoji=$3
    echo -e "${color}${emoji} $message${NC}"
}

get_input() {
    local prompt=$1
    local default=$2
    local value=""
    
    echo -ne "${CYAN}${GLOBE} $prompt ${NC}(default: ${YELLOW}$default${NC}): "
    read -r value
    
    if [ -z "$value" ]; then
        value=$default
    fi
    
    echo "$value"
}

echo -e "\n${BLUE}=========================================================${NC}"
print_message "Docker TLS Certificate Generation Utility" $BLUE "$LOCK"
print_message "Please provide the following information:" $BLUE "$INFO"
echo -e "${BLUE}=========================================================${NC}\n"

# Get user input for variables
SERVER_NAME=$(get_input "Enter server hostname" "docker-server")
SERVER_ALIAS=$(get_input "Enter server alias (alternative hostname)" "docker")
SERVER_IP=$(get_input "Enter server IP address" "192.168.1.100")
CLIENT_NAME=$(get_input "Enter client name" "docker-client")
CERT_DIR=$(get_input "Enter certificates directory" "/etc/docker/tls")
CA_PASSWORD=$(get_input "Enter password for CA private key (remember this!)" "secure_password")

echo -e "\n${YELLOW}${GEAR} Configuration Summary:${NC}"
echo -e "  ${BLUE}•${NC} Server Name: ${GREEN}$SERVER_NAME${NC}"
echo -e "  ${BLUE}•${NC} Server Alias: ${GREEN}$SERVER_ALIAS${NC}"
echo -e "  ${BLUE}•${NC} Server IP: ${GREEN}$SERVER_IP${NC}"
echo -e "  ${BLUE}•${NC} Client Name: ${GREEN}$CLIENT_NAME${NC}"
echo -e "  ${BLUE}•${NC} Certificates Directory: ${GREEN}$CERT_DIR${NC}"
echo -e "  ${BLUE}•${NC} CA Password: ${GREEN}********${NC}"

echo -e "\n${YELLOW}${ROCKET} Ready to proceed with certificate generation?${NC} (y/n)"
read -r proceed

if [[ ! "$proceed" =~ ^[yY]$ ]]; then
    print_message "Operation canceled by user" $RED $ERROR
    exit 1
fi
CA_KEY="${CERT_DIR}/ca-key.pem"
CA_CERT="${CERT_DIR}/ca.pem"
SERVER_KEY="${CERT_DIR}/server-key.pem"
SERVER_CSR="${CERT_DIR}/server.csr"
SERVER_CERT="${CERT_DIR}/server-cert.pem"
CLIENT_KEY="${CERT_DIR}/key.pem"
CLIENT_CSR="${CERT_DIR}/client.csr"
CLIENT_CERT="${CERT_DIR}/cert.pem"

print_message "Creating certificates directory at ${CERT_DIR}..." $YELLOW $INFO
mkdir -p $CERT_DIR

print_message "Generating CA private key..." $YELLOW $INFO
openssl genrsa -aes256 -passout pass:$CA_PASSWORD -out $CA_KEY 4096

print_message "Creating CA certificate..." $YELLOW $INFO
openssl req -new -x509 -days 365 -key $CA_KEY -passin pass:$CA_PASSWORD -sha256 -out $CA_CERT \
    -subj "/CN=Docker CA/O=Docker/OU=CA/C=US"

print_message "Generating server private key..." $YELLOW $INFO
openssl genrsa -out $SERVER_KEY 4096

print_message "Creating server CSR with SANs..." $YELLOW $INFO
openssl req -new -key $SERVER_KEY -out $SERVER_CSR -config <(
cat <<-EOF
[req]
default_bits       = 2048
default_md         = sha256
prompt             = no
distinguished_name = dn
req_extensions     = req_ext

[dn]
CN = $SERVER_NAME

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1   = $SERVER_NAME
DNS.2   = $SERVER_ALIAS
IP.1    = $SERVER_IP
EOF
)

print_message "Generating server certificate..." $YELLOW $INFO
openssl x509 -req -days 365 -sha256 -in $SERVER_CSR -CA $CA_CERT -CAkey $CA_KEY -passin pass:$CA_PASSWORD \
    -CAcreateserial -out $SERVER_CERT -extfile <(
cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1   = $SERVER_NAME
DNS.2   = $SERVER_ALIAS
IP.1    = $SERVER_IP
EOF
)

print_message "Generating client private key..." $YELLOW $INFO
openssl genrsa -out $CLIENT_KEY 4096

print_message "Creating client CSR with SANs..." $YELLOW $INFO
openssl req -new -key $CLIENT_KEY -out $CLIENT_CSR -config <(
cat <<-EOF
[req]
default_bits       = 2048
default_md         = sha256
prompt             = no
distinguished_name = dn
req_extensions     = req_ext

[dn]
CN = $CLIENT_NAME

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1   = $CLIENT_NAME
EOF
)

print_message "Generating client certificate..." $YELLOW $INFO
openssl x509 -req -days 365 -sha256 -in $CLIENT_CSR -CA $CA_CERT -CAkey $CA_KEY -passin pass:$CA_PASSWORD \
    -CAcreateserial -out $CLIENT_CERT -extfile <(
cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1   = $CLIENT_NAME
EOF
)

print_message "Setting secure permissions on certificate files..." $YELLOW $INFO
chmod 0600 ${CERT_DIR}/*.pem
chmod 0600 ${CERT_DIR}/*.csr
chmod 0644 ${CERT_DIR}/ca.pem

print_message "Configuring Docker daemon..." $YELLOW $INFO
DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"
cat <<EOF > $DOCKER_DAEMON_CONFIG
{
  "tls": true,
  "tlscacert": "${CA_CERT}",
  "tlscert": "${SERVER_CERT}",
  "tlskey": "${SERVER_KEY}",
  "tlsverify": true
}
EOF

print_message "Restarting Docker daemon..." $YELLOW $INFO
systemctl restart docker || {
    print_message "Failed to restart Docker daemon. Check status with 'systemctl status docker'" $RED $ERROR
    exit 1
}

print_message "Configuring Docker client..." $YELLOW $INFO
echo "export DOCKER_HOST=tcp://${SERVER_NAME}:2376" > /etc/profile.d/docker-tls.sh
echo "export DOCKER_TLS_VERIFY=1" >> /etc/profile.d/docker-tls.sh
echo "export DOCKER_CERT_PATH=${CERT_DIR}" >> /etc/profile.d/docker-tls.sh
chmod +x /etc/profile.d/docker-tls.sh

print_message "Environment variables for Docker client set in /etc/profile.d/docker-tls.sh" $BLUE $INFO
print_message "Run 'source /etc/profile.d/docker-tls.sh' to apply them in current session" $BLUE $INFO

print_message "Testing Docker client connection..." $YELLOW $INFO
source /etc/profile.d/docker-tls.sh
if docker info >/dev/null 2>&1; then
    print_message "Setup completed successfully! Docker TLS connection works." $GREEN $CHECKMARK
else
    print_message "Docker connection test failed. Please check your configuration." $RED $ERROR
    print_message "Try running 'docker info' manually after fixing issues." $BLUE $INFO
fi

print_message "Remember to back up your certificates from ${CERT_DIR}" $YELLOW $INFO
