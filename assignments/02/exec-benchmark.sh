#!/bin/bash

# This script should start the benchmark on all vms and the host

# ================== HOST ==================

# Prepare result file
echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" >results.csv

# Build the benchmark
make forkbench

# Run benchmark
for i in {1..10}; do
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
echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" >docker-results.csv

# After that the docker image will be runned 10 times
for i in {1..10}; do
  docker run --rm \
    --name benchmark-ass02-$i \
    --mount type=bind,source="$(pwd)"/docker-results.csv,target=/app/results.csv \
    --network="host" \
    benchmark-ass02
done

# ==========================================

# ================== KVM ===================

# Create necessary files on host
echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" >kvm-results.csv

# Prepare KVM for benchmark
ssh -p 2223 -i ~/.ssh/id_rsa root@localhost apt-get update
ssh -p 2223 -i ~/.ssh/id_rsa root@localhost apt-get install build-essential sysbench iperf3 bc -y

# Copy over forkbench.c, benchmark.sh, and KVM-results.csv
scp -P 2223 -i ~/.ssh/id_rsa ./forkbench.c root@localhost:./
scp -P 2223 -i ~/.ssh/id_rsa ./benchmark.sh root@localhost:./
scp -P 2223 -i ~/.ssh/id_rsa ./kvm-results.csv root@localhost:./

# Build the benchmark script
ssh -p 2223 -i ~/.ssh/id_rsa root@localhost "make forkbench"

# Run the benchmark 10 times
for i in {1..10}; do
  ssh -p 2223 -i ~/.ssh/id_rsa root@localhost ./benchmark.sh
done

# Get the results
scp -P 2223 -i ~/.ssh/id_rsa root@localhost:~/results.csv ./kvm-results.csv

# ==========================================

# ================== QEMU ==================

# Create necessary files on host
echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" >qemu-results.csv

# Prepare QEMU for benchmark
ssh -p 2222 -i ~/.ssh/id_rsa root@localhost apt-get update
ssh -p 2222 -i ~/.ssh/id_rsa root@localhost apt-get install build-essential sysbench iperf3 bc -y

# Copy over forkbench.c, benchmark.sh, and QEMU-results.csv
scp -P 2222 -i ~/.ssh/id_rsa ./forkbench.c root@localhost:./
scp -P 2222 -i ~/.ssh/id_rsa ./benchmark.sh root@localhost:./
scp -P 2222 -i ~/.ssh/id_rsa ./qemu-results.csv root@localhost:./

# Build the benchmark script
ssh -p 2222 -i ~/.ssh/id_rsa root@localhost "make forkbench"

# Run the benchmark
for i in {1..10}; do
  ssh -p 2222 -i ~/.ssh/id_rsa root@localhost ./benchmark.sh
done

# Get the results
scp -P 2222 -i ~/.ssh/id_rsa root@localhost:~/results.csv ./qemu-results.csv
# ==========================================
