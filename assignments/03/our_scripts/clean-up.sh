#!/bin/bash


gcloud compute instances delete controller --quiet
gcloud compute instances delete compute1 --quiet
gcloud compute instances delete compute2 --quiet


gcloud compute firewall-rules delete cc-internal-subnet1 --quiet
gcloud compute firewall-rules delete cc-internal-subnet2 --quiet
gcloud compute firewall-rules delete cc-external --quiet

gcloud compute networks subnets delete cc-subnet1 --quiet
gcloud compute networks subnets delete cc-subnet2 --quiet

gcloud compute networks delete cc-network1 --quiet
gcloud compute networks delete cc-network2 --quiet

gcloud compute images delete cc-image --quiet

gcloud compute disks delete cc-disk --quiet
