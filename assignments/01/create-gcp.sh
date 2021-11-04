#!/bin/bash


# TODO: Change to a wildcard approach for the public key; currently it is using the first command argument
# Upload public key to gcloud
gcloud compute os-login ssh-keys add --key-file=$1 --ttl=120d

# Create a gcloud compute instance with the following settings:
# - name: test-instance
# - image: Ubuntu 18.04
# - machine type: e2-standard-2
# - zone: europe-west3-b
gcloud compute instances create test-instance \
  --image-family ubuntu-1804-lts \
  --image-project ubuntu-os-cloud \
  --machine-type e2-standard-2 \
  --zone europe-west3-b

