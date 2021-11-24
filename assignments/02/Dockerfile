FROM ubuntu:18.04

WORKDIR /app

RUN apt-get update
RUN apt-get install build-essential -y

COPY benchmark.sh .
COPY forkbench.c .

RUN make forkbench
RUN rm forkbench.c

CMD ["/bin/bash", "benchmark.sh"]