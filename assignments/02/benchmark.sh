#!/bin/bash
# This script benchmarks CPU, memory and random/sequential disk access.
# Some debug output is written to stderr, and the final benchmark result is output on stdout as a single CSV-formatted line.

# Execute the sysbench tests for the given number of seconds
runtime=60
startvalue=1
endvalue=2000
iperf3host="127.0.0.1"
iperf3port=5201

# Record the Unix timestamp before starting the benchmarks.
time=$(date +%s)

# Run the sysbench CPU test and extract the "events per second" line.
1>&2 echo "Running CPU test..."
cpu=$(sysbench --time=$runtime cpu run | grep "events per second" | awk '/ [0-9.]*$/{print $NF}')

# Run the sysbench memory test and extract the "transferred" line. Set large total memory size so the benchmark does not end prematurely.
1>&2 echo "Running memory test..."
mem=$(sysbench --time=$runtime --memory-block-size=4K --memory-total-size=100T memory run | grep -oP 'transferred \(\K[0-9\.]*')

# Prepare one file (1GB) for the disk benchmarks
1>&2 sysbench --file-total-size=1G --file-num=1 fileio prepare

# Run the sysbench sequential disk benchmark on the prepared file. Use the direct disk access flag. Extract the number of read MiB.
1>&2 echo "Running fileio sequential read test..."
diskSeq=$(sysbench --time=$runtime --file-test-mode=seqrd --file-total-size=1G --file-num=1 --file-extra-flags=direct fileio run | grep "read, MiB" | awk '/ [0-9.]*$/{print $NF}')

# Run the sysbench random access disk benchmark on the prepared file. Use the direct disk access flag. Extract the number of read MiB.
1>&2 echo "Running fileio random read test..."
diskRand=$(sysbench --time=$runtime --file-test-mode=rndrd --file-total-size=1G --file-num=1 --file-extra-flags=direct fileio run | grep "read, MiB" | awk '/ [0-9.]*$/{print $NF}')

#clean up created files to save on storage
sysbench fileio \
         --file-num=1 \
         cleanup >/dev/null     #discard output


#run the forkbench.c script
1>&2 echo "Running forkbench script with start value $startvalue and end value $endvalue..."
endtime=$((SECONDS+60))
count=0
allforks=0

#execute loop for 60 seconds
while [ $SECONDS -lt $endtime ]; do
        fork=$(./forkbench $startvalue $endvalue)
        allforks=$(awk "BEGIN{ print $allforks + $fork }")
        count=$((count+1))
        :
done

forkres=$(echo "scale=2; $allforks / $count" | bc) 	#compute average

ping -c1 -W1 10.0.2.2 && iperf3host=10.0.2.2 # change ip of iperf3 server if run on guest vm

#benchmark network upload speed
1>&2 echo "Testing upload speed with iperf3 on server $iperf3host and port $iperf3port"
iperf3 -f MBytes -c $iperf3host --logfile iperf.log --time $runtime -p $iperf3port -P5 -4 			#write iperf output into iperf.log
iperfbench=$(cat iperf.log | grep sender | grep SUM | grep -o "\w*.\w* MBytes/sec" | cut -d' ' -f1) 	        #extract upload throughput
if [[ -z "${iperfbench// }" ]]                                                                                       #sometimes the first string is empty
then 
        iperfbench=$(cat iperf.log | grep sender | grep SUM | grep -o "\w*.\w* MBytes/sec" | cut -d' ' -f2) 	#extract upload throughput
fi
if [[ -z "${iperfbench// }" ]]  
then 
        iperfbench=$(cat iperf.log | grep sender | grep SUM | grep -o "\w*.\w* Mbits/sec" | cut -d' ' -f1) 	#extract upload throughput
fi

iperfbench=$(echo $iperfbench*8 | bc)                                                                           #convert bytes to bits

rm iperf.log

# Output the benchmark results as one CSV line
echo "$time,$cpu,$mem,$diskRand,$diskSeq,$forkres,$iperfbench" >> results.csv

