#!/bin/bash

CONFIG_FILE="/etc/wireguard/wg1.conf"

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found!"
    exit 1
fi

# Extract the PresharedKey and PrivateKey
PRESHARED_KEY=$(grep -Po '(?<=PresharedKey = ).*' "$CONFIG_FILE")
PRIVATE_KEY=$(grep -Po '(?<=PrivateKey = ).*' "$CONFIG_FILE")

# Check if keys are found
if [ -z "$PRESHARED_KEY" ]; then
    echo "Error: PresharedKey not found in $CONFIG_FILE"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PrivateKey not found in $CONFIG_FILE"
    exit 1
fi

# Generate the PublicKey from the PrivateKey
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)

# Print the export commands
echo "export PEER_PUBLIC_KEY=\"$PUBLIC_KEY\""
echo "export PRESHARED_KEY=\"$PRESHARED_KEY\""
