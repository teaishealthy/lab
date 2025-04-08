#!/bin/bash
# This script creates a certificate using the BounCA API.
# It retrieves credentials from Bitwarden and uses them to authenticate with the BounCA API.

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <commonName>"
    exit 1
fi

COMMON_NAME="$1"

# Get the current date + 1 year in YYYY-MM-DD format
EXPIRES_AT=$(date -d "+1 year" +"%Y-%m-%d")

# Get the item data from Bitwarden using bw CLI
ITEM_JSON=$(bw get item bounca.home)

# Extract username, password, and PASSPHRASE_ISSUER from the item data
USERNAME=$(echo "$ITEM_JSON" | jq -r '.login.username')
PASSWORD=$(echo "$ITEM_JSON" | jq -r '.login.password')
PASSPHRASE_ISSUER=$(echo "$ITEM_JSON" | jq -r '.fields[0].value')

# Check if all values were extracted successfully
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$PASSPHRASE_ISSUER" ]; then
    echo "❌ Failed to extract username, password, or passphrase issuer from Bitwarden item."
    exit 1
fi

echo "✅ Successfully retrieved credentials from Bitwarden."

# Login to get the API token
LOGIN_URL="https://bounca.home/api/v1/auth/login/"
LOGIN_RESPONSE=$(curl -s -X POST "$LOGIN_URL" \
    -H "Content-Type: application/json" \
    -d '{"username": "'"$USERNAME"'", "password": "'"$PASSWORD"'"}')

# Extract the token from the login response
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.key')

# Check if we got the token
if [ -z "$TOKEN" ]; then
    echo "❌ Failed to authenticate. Please check your credentials."
    exit 1
fi

echo "✅ Successfully logged in. Token obtained."

# Construct JSON for creating the certificate
# Set "name" equal to "commonName"
JSON=$(jq -n --arg cn "$COMMON_NAME" \
              --arg expires_at "$EXPIRES_AT" \
              --arg passphrase "$PASSPHRASE_ISSUER" \
              '{
                  "name": $cn,
                  "parent": 2,
                  "type": "S",
                  "dn": {
                      "commonName": $cn,
                      "countryName": "DE",
                      "stateOrProvinceName": "NRW",
                      "localityName": "",
                      "organizationName": "homelab",
                      "organizationalUnitName": "",
                      "emailAddress": "",
                      "subjectAltNames": [$cn]
                  },
                  "expires_at": $expires_at,
                  "crl_distribution_url": "",
                  "ocsp_distribution_host": "",
                  "passphrase_issuer": $passphrase,
                  "passphrase_out": "",
                  "passphrase_out_confirmation": ""
              }'
)

# Send POST request to create the certificate
CREATE_CERT_URL="https://bounca.home/api/v1/certificates"
CREATE_CERT_RESPONSE=$(curl -s -X POST "$CREATE_CERT_URL" \
    -H "Authorization: Token $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON")

# Echo the create certificate response
echo "Create Certificate Response: $CREATE_CERT_RESPONSE"

# Extract certificate ID from the response
CERT_ID=$(echo "$CREATE_CERT_RESPONSE" | jq -r '.id')

# Check if ID was extracted successfully
if [ -z "$CERT_ID" ] || [ "$CERT_ID" == "null" ]; then
    echo "❌ Failed to retrieve certificate ID."
    exit 1
fi

echo "📄 Certificate created with ID: $CERT_ID"

# Download the certificate bundle using the obtained token
CERT_BUNDLE_URL="https://bounca.home/api/v1/certificates/$CERT_ID/download"
curl -s -O -J -H "Authorization: Token $TOKEN" "$CERT_BUNDLE_URL"

echo "✅ Certificate bundle downloaded successfully."