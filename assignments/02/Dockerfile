FROM ubuntu:18.04

WORKDIR /app

RUN apt-get update
RUN apt-get install build-essential sysbench iperf3 bc -y

COPY benchmark.sh .
COPY forkbench.c .

RUN make forkbench
RUN rm forkbench.c

# Touch result file
RUN touch results.csv

# CMD "/bin/bash benchmark.sh >> /app/results.csv"

CMD ["/bin/bash", "benchmark.sh"]