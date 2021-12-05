#!/bin/bash

# This script should start the benchmark on all vms and the host

# ================== HOST ==================

# Prepare result file
echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" > results.csv

# Build the benchmark
make forkbench

# Run benchmark
for i in {1..10} ; do
    echo "Running native benchmark $i"
    ./benchmark.sh
done

# Rename results file
mv results.csv native-results.csv


# Build the benchmark script



# ================= Docker =================
# First the docker image will be build
docker build -t benchmark-ass02 .

# Create the docker result file on host
# touch docker-results.csv
echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" > docker-results.csv

# After that the docker image will be runned 10 times
for i in {1..10} ; do
    docker run --rm \
      --name benchmark-ass02-$i \
      --mount type=bind,source="$(pwd)"/docker-results.csv,target=/app/results.csv \
      benchmark-ass02
done

# ==========================================


# ================== KVM ===================
# TODO: Needs further implementation
KVM_USER=root
KVM_PASSWORD=root
KVM_IP=10.0.10.1

# Create necessary files on host
echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" > kvm-results.csv

# Prepare KVM for benchmark
ssh $KVM_IP apt-get update
ssh $KVM_IP apt-get install build-essential sysbench iperf3 bc -y

# Copy over forkbench.c, benchmark.sh, and kvm-results.csv
scp ./forkbench.c $KVM_USER@$KVM_IP:/home/$KVM_USER/
scp ./benchmark.sh $KVM_USER@$KVM_IP:/home/$KVM_USER/
scp ./kvm-results.csv $KVM_USER@$KVM_IP:/home/$KVM_USER/results.csv


# Build the benchmark script
ssh $KVM_USER@$KVM_IP "make forkbench"


# Run the benchmark 10 times
for i in {1..10} ; do
  ssh $KVM_USER@$KVM_IP ./benchmark.sh
done

# Get the results
scp $KVM_IP:~/results.csv ./kvm-results.csv


# ==========================================



# ================== QEMU ==================
# TODO: Needs further implementation
QEMU_USER=root
QEMU_PASSWORD=root
QEMU_IP=10.0.10.1

# Create necessary files on host
echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" > qemu-results.csv

# Prepare QEMU for benchmark
ssh $QEMU_IP apt-get update
ssh $QEMU_IP apt-get install build-essential sysbench iperf3 bc -y

# Copy over forkbench.c, benchmark.sh, and QEMU-results.csv
scp ./forkbench.c $QEMU_USER@$QEMU_IP:/home/$QEMU_USER/
scp ./benchmark.sh $QEMU_USER@$QEMU_IP:/home/$QEMU_USER/
scp ./qemu-results.csv $QEMU_USER@$QEMU_IP:/home/$QEMU_USER/results.csv

# Build the benchmark script
ssh $QEMU_USER@$QEMU_IP "make forkbench"

# Run the benchmark
for i in {1..10} ; do
  ssh $QEMU_USER@$QEMU_IP ./benchmark.sh
done

# Get the results
scp $QEMU_IP:~/results.csv ./qemu-results.csv
# ==========================================