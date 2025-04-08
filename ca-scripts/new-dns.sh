#!/bin/bash
# This script adds a DNS entry to Pi-hole using the Pi-hole API.
# It requires the Bitwarden CLI to retrieve the password for authentication.

# Check if an argument is provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <IP_ADDRESS> <HOSTNAME>"
    exit 1
fi

IP_ADDRESS="$1"
HOSTNAME="$2"

# Ask for the password to authenticate and retrieve the SID token
PASSWORD=$(bw get password pihole.home)
# Authenticate and retrieve the SID token
AUTH_URL="https://pihole.home:443/api/auth"

AUTH_RESPONSE=$(curl -s -X POST "$AUTH_URL" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{\"password\": \"$PASSWORD\"}")



echo $AUTH_RESPONSE
# Extract the SID token from the response
SID_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.session.sid')

# Check if SID token is retrieved
if [ -z "$SID_TOKEN" ] || [ "$SID_TOKEN" == "null" ]; then
    echo "❌ Failed to authenticate. Please check your password."
    exit 1
fi

echo "✅ Authentication successful. SID token obtained."

# Validate IP Address Format
if ! echo "$IP_ADDRESS" | grep -Pq '^(\d{1,3}\.){3}\d{1,3}$'; then
    echo "❌ Invalid IP address format."    
    exit 1
fi

# Construct the URL
ENCODED_HOST=$(echo "$IP_ADDRESS $HOSTNAME" | sed 's/ /%20/g')  # URL encode the IP and hostname
URL="https://pihole.home:443/api/config/dns%2Fhosts/$ENCODED_HOST"

# Send PUT request to add the DNS entry
RESPONSE=$(curl -s -X PUT "$URL" \
    -H "accept: application/json" \
    -H "sid: $SID_TOKEN")

# Check if the response indicates success
if echo "$RESPONSE" | jq -e '.error' > /dev/null; then
    echo "❌ Failed to add DNS entry. Response: $RESPONSE"
    exit 1
fi
echo "✅ DNS entry $IP_ADDRESS -> $HOSTNAME successfully added."