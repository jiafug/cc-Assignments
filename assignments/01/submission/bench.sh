#!/bin/bash

output=$(date +%s)	#get unix EPOCH timestamp
extime=60		#variable to set execution time


################### benchmarking cpu ####################################

#benchmark cpu and pipe into file "out"
sysbench cpu \
	 --time=$extime \
	 run > out

cpu_events=$(grep "events per second" out | grep -o "\w*[.0-9]\w*") 	#filter out number of events/s
output+=,$cpu_events		 					#append events/s to output line


############## benchmarking memory ####################################

#benchmark memory
sysbench memory \
	 --memory-block-size=4K \
	 --memory-total-size=100T \
	 --time=$extime \
	 run > out

mem_mib_s=$(grep "transferred" out | grep -o "\w*[.0-9]\w*" | cut -d$'\n' -f2)	#extract MiB/s from output
output+=,$mem_mib_s 								#append to output line

############### benchmarking disk access ################################

#prepare 1 file of size 1GB with direct disk access for disk benchmarking
sysbench fileio \
	 --file-num=1 \
	 --file-total-size=1G \
	 --file-extra-flags=direct \
	 prepare >/dev/null 	#discard output

#benchmark random-access disk read speed
sysbench fileio \
	 --file-num=1 \
	 --file-total-size=1G \
	 --file-test-mode=rndrd \
	 --time=$extime \
	 --file-extra-flags=direct \
	 run > out

rndrd_disk_speed=$(grep "read, MiB/s:" out | grep -o "\w*[.0-9]\w*")	#extract MiB/s from sysbench output
output+=,$rndrd_disk_speed						#append MiB/s to output line

#benchmark sequential-access disk read spead 
sysbench fileio \
         --file-num=1 \
         --file-total-size=1G \
         --file-test-mode=seqrd \
         --time=$extime \
	 --file-extra-flags=direct \
         run > out

seqrd_disk_speed=$(grep "read, MiB/s:" out | grep -o "\w*[.0-9]\w*")	#extract MiB/s from sysbench output
output+=,$seqrd_disk_speed						#append MiB/s to output line
rm out									#remove file "out"


#clean up created files
sysbench fileio \
	 --file-num=1 \
	 cleanup >/dev/null     #discard output

echo $output	#output csv line

