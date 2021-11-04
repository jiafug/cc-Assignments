#!/bin/bash

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

