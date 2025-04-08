#!/bin/bash
# This script is used to enroll a certificate from a zip file and update the Traefik configuration.
# It assumes the zip file is named <servername>.server_cert.zip and contains the server's cert and key files.

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root." 
    exit 1
fi

# Define the path where the certs will be stored
CERTS_DIR="/root/certs"
TRAFFIC_YML="/root/certs-traefik.yml"

# Find the zip file with the pattern <servername>.server_cert.zip
ZIP_FILE=$(ls *.server_cert.zip)

# Check if the zip file exists
if [ ! -f "$ZIP_FILE" ]; then
    echo "No .server_cert.zip file found in the current directory."
    exit 1
fi

# Extract server name from the zip file name (remove the '.server_cert.zip' extension)
SERVER_NAME="${ZIP_FILE%.server_cert.zip}"

# Create the certs directory if it doesn't exist
mkdir -p "$CERTS_DIR"

# Unzip the zip file into a temporary directory
TEMP_DIR=$(mktemp -d)
unzip "$ZIP_FILE" -d "$TEMP_DIR"

# Find the .pem and .key files explicitly
PEM_FILE=$(find "$TEMP_DIR" -type f -name "${SERVER_NAME}.pem")
KEY_FILE=$(find "$TEMP_DIR" -type f -name "${SERVER_NAME}.key")

# Check if both cert and key files are found
if [ -z "$PEM_FILE" ] || [ -z "$KEY_FILE" ]; then
    echo "Certificate or key files not found in the zip archive."
    exit 1
fi

# Copy the cert and key files to the correct location
cp "$PEM_FILE" "/root/certs/$SERVER_NAME.pem"
cp "$KEY_FILE" "/root/certs/$SERVER_NAME.key"

# Add the entry to the certs-traefik.yml
echo "Adding entry to $TRAFFIC_YML..."
echo "    - certFile: /etc/certs/$SERVER_NAME.pem" >> "$TRAFFIC_YML"
echo "      keyFile: /etc/certs/$SERVER_NAME.key" >> "$TRAFFIC_YML"

# Delete the extracted temporary directory and the zip file
rm -rf "$TEMP_DIR"
rm "$ZIP_FILE"

echo "Process completed successfully."