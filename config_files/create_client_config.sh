#!/bin/bash

# Generate the private and public keys
private_key=$(wg genkey)
public_key=$(echo "${private_key}" | wg pubkey)

# Generate a pre-shared key
preshared_key=$(wg genpsk)

# Print the generated public key
echo "Generated Public Key: ${public_key}"

# Export the keys as environment variables
export PEER_PUBLIC_KEY=${public_key}
export PRESHARED_KEY=${preshared_key}

# Create the configuration file
cat >wg1.conf <<EOL
[Interface]
PrivateKey = ${private_key}
ListenPort = 51820
Address = 10.0.0.2/32
#DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = SERVER_IP:51820
PresharedKey = ${preshared_key}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOL

# Inform the user
echo "Configuration saved to wg1.conf with placeholder 'SERVER_PUBLIC_KEY' for server's public key."

# Ask the user if they want to move the file to /etc/wireguard/wg1.conf
read -p "Would you like to save the configuration file to /etc/wireguard/wg1.conf? (y/n): " choice
if [[ $choice == [Yy]* ]]; then
    sudo mv wg1.conf /etc/wireguard/wg1.conf
    sudo chmod 600 /etc/wireguard/wg1.conf
    echo "Configuration file moved to /etc/wireguard/wg1.conf"
else
    echo "Configuration file left in the current directory as wg1.conf"
fi

# Print the export commands
echo "Run the following commands to set the environment variables:"
echo "export PEER_PUBLIC_KEY=${PEER_PUBLIC_KEY} && export PRESHARED_KEY=${PRESHARED_KEY}"
