#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 --public-key <new-public-key> [--endpoint <new-endpoint>]"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --public-key)
            NEW_PUBLIC_KEY="$2"
            shift
            ;;
        --endpoint)
            NEW_ENDPOINT="$2"
            shift
            ;;
        *) usage ;;
    esac
    shift
done

# Check if public key is provided
if [ -z "$NEW_PUBLIC_KEY" ]; then
    usage
fi

CONFIG_FILE="/etc/wireguard/wg1.conf"

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found!"
    exit 1
fi

# Update the PublicKey in the configuration file
sudo sed -i "s|PublicKey = .*|PublicKey = $NEW_PUBLIC_KEY|" $CONFIG_FILE

# Update the Endpoint in the configuration file if provided
if [ ! -z "$NEW_ENDPOINT" ]; then
    sudo sed -i "s|Endpoint = .*|Endpoint = $NEW_ENDPOINT:51820|" $CONFIG_FILE
fi

echo "Configuration updated successfully in $CONFIG_FILE"
