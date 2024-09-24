#!/bin/bash
# Update and upgrade the system
sudo apt-get update && sudo apt-get upgrade -y

# Install necessary packages
sudo apt-get install -y wireguard iptables-persistent curl

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf

# Setup NAT with iptables
PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}')
sudo iptables -t nat -A POSTROUTING -o $PRIMARY_INTERFACE -j MASQUERADE

# Save iptables rules
sudo netfilter-persistent save

# Create WireGuard configuration directory
sudo mkdir -p /etc/wireguard

# # Generate WireGuard private and public keys if they do not exist
# if [ ! -f /etc/wireguard/server_private.key ]; then
#     sudo wg genkey | sudo tee /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key
# fi

# # Output the public key
# echo "WireGuard Public Key:"
# sudo cat /etc/wireguard/server_public.key
