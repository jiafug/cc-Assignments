#!/bin/bash

#set key permissions to 400
chmod 400 ssh_keys/openstack_key ssh_keys/openstack_key.pub ssh_keys/id_rsa

#copy private key to gc controller or generate it there
scp -i ssh_keys/id_rsa ssh_keys/openstack_key user@34.78.115.252:.ssh

