#!/usr/bin/env bash

# # create a new script folder
# mkdir -p cc_scripts

# # change directory to new script folder
# cd cc_scripts

# generate a new ssh key without passphrase
ssh-keygen -t rsa -f id_rsa -C user -P ""

# read the ssh key
key=$(<id_rsa.pub)

# array of splitted key; split on space
array=(${key// / })

# get the user
user=${array[2]}

# build a gcp compliant ssh key
newKey="${user}: ${key}"

# write new key to file
echo $newKey >id_rsa_gcp.pub

# add new key to project metadata
gcloud compute project-info add-metadata \
    --metadata-from-file ssh-keys=id_rsa_gcp.pub

# create firewall rule, tcp port 22 for ssh connection
gcloud compute firewall-rules create new-firewall-rule \
    --allow=tcp:22,icmp \
    --target-tags=cloud-computing

# start vm
gcloud compute instances create test-vm \
    --machine-type=e2-standard-2 \
    --zone=europe-west3-b \
    --tags=cloud-computing \
    --image-family=ubuntu-1804-lts \
    --image-project=ubuntu-os-cloud

# resize disk
gcloud compute disks resize test-vm \
    --size 100GB \
    --zone=europe-west3-b \
    --quiet

#define a benchmarking cronjob with command 
# */30 * * * * ./bench.sh >> tmp/gcp_results.csv 
#in file cronjob.txt and execute it with 
#crontab cronjob.txt
#remove cronjob after 2 days with 
#crontab -r
