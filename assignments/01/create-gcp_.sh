#!/usr/bin/env bash

cd ~/Desktop/cc

# generate key without passphrase
ssh-keygen -t rsa -f id_rsa -C user -P ""

# read key
key=$(<id_rsa.pub)

# array of splitted key
array=(${key// / })

# get the user
user=${array[2]}

# build new key
newKey="${user}: ${key}"

# write new key to file
echo $newKey >id_rsa_gcp.pub

# add new key to project metadata
gcloud compute project-info add-metadata \
    --metadata-from-file ssh-keys=id_rsa_gcp.pub

# create firewall rule
gcloud compute firewall-rules create new-firewall-rule \
    --allow=tcp:22,icmp \
    --target-tags=cloud-computing

# start vm
gcloud compute instances create test-vm \
    --machine-type=e2-standard-2 \
    --zone=us-west1-a \
    --tags=cloud-computing \
    --image-family=ubuntu-1804-lts \
    --image-project=ubuntu-os-cloud

# resize disk
gcloud compute disks resize test-vm \
    --size 100GB \
    --zone=us-west1-a \
    --quiet
