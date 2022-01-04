#!/bin/bash


# Requirement 1: Create two VPC networks "cc-network1" and "cc-network2" with subnet mode "custom"
gcloud compute networks create cc-network1 --quiet --subnet-mode=custom
gcloud compute networks create cc-network2 --quiet --subnet-mode=custom

# Requirement 2: Create two VPC subnets "cc-subnet1" and "cc-subnet2" in the networks "cc-network1" and "cc-network2"
# assign different ip ranges to them
# cc-subnet1 needs a secondary range (--secondary range parameter)
# cc-subnet 1:
#   10.10.0.0/24
#   10.10.1.0/24
# cc-subnet 2:
#   10.11.0.0/24
gcloud compute networks subnets create cc-subnet1 --quiet --network cc-network1 --range 10.10.0.0/24 --secondary-range cc-subnet1-sr=10.10.1.0/24
gcloud compute networks subnets create cc-subnet2 --quiet --network cc-network2 --range 10.11.0.0/24

# Requirement 3: Checking google docs for nested virtualization
# done

# Requirement 4: Creating a disk based on the ubuntu-2004-lts image family and set the size to at least 100GB
gcloud compute disks create cc-disk --quiet --image-project=ubuntu-os-cloud --image-family ubuntu-2004-lts --size 100GB

# Requirement 5: Use the disk to create a custom image and include the required license for nested virtualization
gcloud compute images create cc-image --quiet --source-disk cc-disk --licenses "https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"
# Delete the disk, because its not needed anymore
gcloud compute disks delete cc-disk --quiet

# Requirement 6: Start 3 VMs that allow nested virtualization
# first vm:
#  name: controller
#  machine type: n2-standard-2
#  image: cc-image
#  tags:
#    - cc
#  two nics:
#    - cc-subnet1
#    - cc-subnet2
# second vm:
#   name: compute1
#   machine type: n2-standard-2
#   image: cc-image
#  tags:
#    - cc
#   two nics:
#     - cc-subnet1
#     - cc-subnet2
# third vm:
#   name: compute2
#   machine type: n2-standard-2
#   image: cc-image
#  tags:
#    - cc
#   two nics:
#     - cc-subnet1
#     - cc-subnet2
gcloud compute instances create controller \
 --quiet \
 --machine-type n2-standard-2 \
 --image cc-image \
 --tags cc \
 --network-interface subnet=cc-subnet1,private-network-ip=10.10.0.2 \
 --network-interface subnet=cc-subnet2,private-network-ip=10.11.0.2
gcloud compute instances create compute1 \
 --quiet \
 --machine-type n2-standard-2 \
 --image cc-image \
 --tags cc \
 --network-interface subnet=cc-subnet1,private-network-ip=10.10.0.3 \
 --network-interface subnet=cc-subnet2,private-network-ip=10.11.0.3
gcloud compute instances create compute2 \
 --quiet \
 --machine-type n2-standard-2 \
 --image cc-image \
 --tags cc \
 --network-interface subnet=cc-subnet1,private-network-ip=10.10.0.4 \
 --network-interface subnet=cc-subnet2,private-network-ip=10.11.0.4

# Requirement 7: Create a firewall rule that allows TCP, ICMP and IDP traffic for the ip ranges of the subnets. Restrict to CMs that have the cc tag.
gcloud compute firewall-rules create cc-internal-subnet1 --quiet --network cc-network1 --allow tcp,icmp,udp --source-ranges 10.10.0.0/24,10.10.1.0/24,10.11.0.0/24 --target-tags cc
gcloud compute firewall-rules create cc-internal-subnet2 --quiet --network cc-network2 --allow tcp,icmp,udp --source-ranges 10.10.0.0/24,10.10.1.0/24,10.11.0.0/24 --target-tags cc

# Requirement 8: Access from the outside to the cc-network1 for all tcp and icmp traffic
gcloud compute firewall-rules create cc-external --quiet --network cc-network1 --allow tcp,icmp,udp --target-tags cc
