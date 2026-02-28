#!/bin/bash
# This script automates the process of:
# - requesting a new server certificate from BounCA
# - enrolling the certificate into Traefik
# - adding a new DNS record to Pi-hole

if [ $# -lt 1 ]; then
    echo "Usage: $0 <SERVER_DOMAIN>"
    exit 1
fi

SERVER_DOMAIN="$1"

echo "Please enter your master password:"
read -s MASTER_PASSWORD

echo "Requesting new server certificate from BounCA"
echo "$MASTER_PASSWORD" | ./pki-add.sh "$SERVER_DOMAIN"

echo "Enrolling certificate into Traefik"
./enroll-cert.sh

echo "Adding new DNS Record to pihole"
echo "$MASTER_PASSWORD" | ./new-dns.sh "10.0.0.34" "$SERVER_DOMAIN"