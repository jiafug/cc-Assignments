#!/bin/bash

#start docker, minikube
#sudo systemctl start dock
minikube --memory 4096 --cpus 2 start

#add hadoop repo (execute only once)
#helm repo add stable https://charts.helm.sh/stable

helm install hadoop    --set yarn.nodeManager.resources.limits.memory=4096Mi     --set yarn.nodeManager.replicas=1     stable/hadoop

#transfer Wordcount data to hadoop
#POD_NAME=$(kubectl get pods | grep yarn-nm | awk '{print $1}')
kubectl cp tolstoy-war-and-peace.txt "${POD_NAME}":/home

#firing up shell in hadoop
#kubectl exec -it ${POD_NAME} -- bash

# Commands to be run inside the pod
hdfs dfs -mkdir /user
hdfs dfs -mkdir /user/root
hdfs dfs -mkdir input
hdfs dfs -put tolstoy-war-and-peace.txt input
#/user/root/tolstoy-war-and-peace.txt


flink run examples/streaming/WordCount.jar  --input hdfs://user/root/input/tolstoy-war-and-peace.txt

#------deploying flink
#if using minikube:
minikube ssh 'sudo ip link set docker0 promisc on'

#creating a bunch of config files
kubectl create -f flink_install_files/flink-configuration-configmap.yaml
kubectl create -f flink_install_files/jobmanager-service.yaml

# Create the deployments for the cluster
kubectl create -f flink_install_files/jobmanager-session-deployment.yaml
kubectl create -f flink_install_files/taskmanager-session-deployment.yaml

#open flink dashboard and submit job manually

#the 2nd command can only execute when the jobmanager pod is running
#exec 'kubectl get pod' to see if it's ready
#then execute both cmds manually
JOBMANAGER_POD=$(kubectl get pods | grep jobmanager | awk '{print $1}')
kubectl port-forward ${JOBMANAGER_POD} 8081:8081

#access dashboard at localhost:8081
