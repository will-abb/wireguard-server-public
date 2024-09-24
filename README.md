# Wireguard Server Infrastructure

This repository provisions and configures a Wireguard server and client using Terraform and Ansible.

## Prerequisites
- AWS CLI and credentials configured
- Terraform
- Ansible with AWS plugins
- Boto3

## Setup

1. **Initialize Terraform**
```bash
cd /home/wil031583/repositories/bitbucket/williseed1/wireguard-server/terraform/
terraform init
```

2. **Apply Terraform Configuration**
```bash
terraform apply
```

3. **Run Locally to setup wireguard**
```bash
sudo apt install wireguard
```

4.  **Create Local Configs**
```bash
bash ~/repositories/bitbucket/williseed1/wireguard-server/config_files/create_client_config.sh
```
This creates client config files. Also `run command` at end of output to export variables for ansbile playbook.

5. **Setup Server**
Activate your virtual environment if needed.
```bash
ansible-playbook -i ~/repositories/bitbucket/williseed1/wireguard-server/ansible/inventories/aws_ec2.yaml ~/repositories/bitbucket/williseed1/wireguard-server/ansible/tasks/setup/setup_wireguard.yaml
```
This will print the public key, copy it in your config file for clients.
*Update local config with the public key printed in the end*

**This copies the public server key and dns name to /etc/wireguard/wg1.conf**
``` bash
sudo bash ~/repositories/bitbucket/williseed1/wireguard-server/config_files/add_server_public_key_and_endpoint.sh --public-key  +AtmzPOlCVXZb20shyelsasdf= --endpoint wireguard.williseed.com
```
*must run above script as sudo*
    
6. **Restart Wireguard Services**
```bash
ansible-playbook -i ~/repositories/bitbucket/williseed1/wireguard-server/ansible/inventories/aws_ec2.yaml ~/repositories/bitbucket/williseed1/wireguard-server/ansible/tasks/manage/restart_wireguard_client_server.yaml
```
*this is both locally and at server*
7. **Add Security Cron Jobs**
```bash
ansible-playbook -i ~/repositories/bitbucket/williseed1/wireguard-server/ansible/inventories/aws_ec2.yaml ~/repositories/bitbucket/williseed1/wireguard-server/ansible/tasks/security/crons.yaml
```

## Management Scripts
These might need to be run if something changes but the server hasn't been destroyed.

- **Get Server Info**
If you need the server info, including key run.
```bash
ansible-playbook -i ~/repositories/bitbucket/williseed1/wireguard-server/ansible/inventories/aws_ec2.yaml ~/repositories/bitbucket/williseed1/wireguard-server/ansible/tasks/manage/fetch_server_info.yaml
```

- **Move Local Config File to Etc**
```bash
mv ~/repositories/bitbucket/williseed1/wireguard-server/config_files/wg1-client.conf /etc/wireguard 
chmod 600 /etc/wireguard/wg1-client.conf 
``` 
    
- **Remove Peer Key From Server**
```bash
ansible-playbook -i ~/repositories/bitbucket/williseed1/wireguard-server/ansible/inventories/aws_ec2.yaml ~/repositories/bitbucket/williseed1/wireguard-server/ansible/tasks/manage/remove_all_peers_from_server.yaml
``` 


- **Get Client Shared and Public Keys for Server**
*this is if you wanted to add the keys to the server and the env vars changed*
```bash
sudo bash ~/repositories/bitbucket/williseed1/wireguard-server/config_files/get_client_shared_and_public_key.sh
``` 
Run the export command at the end

- **Add Peer Key to Server**
*optional*
```bash
ansible-playbook -i ~/repositories/bitbucket/williseed1/wireguard-server/ansible/inventories/aws_ec2.yaml ~/repositories/bitbucket/williseed1/wireguard-server/ansible/tasks/manage/add_peer_key_to_server.yaml
``` 

## Wireguard commands

### Connecting to the WireGuard Interface
```bash
sudo wg-quick up wg1
```

### Disconnecting from the WireGuard Interface
```bash
sudo wg-quick down wg1
```

### Checking the Status of the WireGuard Interface
```bash
sudo wg show wg1
```

### Viewing All Active WireGuard Interfaces
```bash
sudo wg show
```

### 5. Checking the Interface Status via `ip` Command
```bash
ip address show wg1
```

### 6. Restarting the WireGuard Interface
```bash
sudo wg-quick down wg1 && sudo wg-quick up wg1
```

## Notes 
**Just run a Terraform Applya and it'll update the IP address of the instance you've stopped.**
**Remember to delete your created wireguard key from the repo**

## Common Problems
1.  Remember to run Terraform Apply whenever you turn the server on so that it updates the DNS record to the new IP address.
2.  If there is an issue with the WireGuard server processing the address line, go ahead and delete the file and recreate it. Reboot the server and then make sure you change the permissions of the file back to `chmod 600`
2.  If the client has an issue connecting, make sure you uncomment the DNS line. If there's still an issue make sure you delete the ipv6 servers. 
3.  other combinations are probably mismatching public and private keys so check those
