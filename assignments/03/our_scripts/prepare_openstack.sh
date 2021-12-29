#!/bin/bash

IPADDRESS='34.78.115.252'

#create security group "open_all"
openstack security group create open_all

#------------allow all TCP, UDP and ICMP ingress and egress-------------
openstack security group rule create open_all\
	--protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0

openstack security group rule create \
	--protocol udp --dst-port 53:53 open_all

openstack security group rule create --protocol icmp open_all

#----------------create and import key-pair----------------------------
#openstack keypair create openstack_key > openstack_key.pem

#create key pair
ssh-keygen -t rsa -f ssh_keys/openstack_key -P "" #-C user

#set key permissions to 400
chmod 400 ssh_keys/openstack_key ssh_keys/openstack_key.pub

#import public key to openstack
openstack keypair create --public-key ssh_keys/openstack_key.pub openstack_key

#copy private key to gc controller or generate it there
scp -q -i ssh_keys/id_rsa ssh_keys/openstack_keys user@$IPADDRESS:/home

#----------------------------start VM instance--------------------------
openstack server create --flavor m1.medium --image "ubuntu-16.04" \
  --nic net-id=admin-net --security-group open_all \
  --key-name openstack_key provider-instance

#----------------------------create floating IP address------------------
#https://docs.openstack.org/ocata/user-guide/cli-manage-ip-addresses.html

#openstack floating ip create public

#openstack server add floating ip INSTANCE_NAME_OR_ID FLOATING_IP_ADDRESS
