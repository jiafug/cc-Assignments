#!/bin/bash

#generate ssh keypair
ssh-keygen -t rsa -f id_rsa -C user -P ""

#read public ssh key into variable
key=$(<id_rsa.pub)

#check for existing vpcs
listVPC=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[*].[IsDefault]' --output text)

#check if there is no default VPC
if [[ ! $listVPC = "True" ]]
then
	#if there is no default VPC, create one
	aws ec2 create-default-vpc
fi


#upload the keyfile
aws ec2 import-key-pair --key-name id_rsa --public-key-material fileb://id_rsa.pub

#if desired, we can create our own IAM role with the following command
#aws iam create-role --role-name EC2Assignment1 --assume-role-policy-document file://IAMPolicyAssignment1.json

#create a security-group without entries
aws ec2 create-security-group --group-name EC2deployLinuxInstance --description "For launching a Linux Server"

#set ingress rules to the created security-group. Every other port to access from outside is blocked
aws ec2 authorize-security-group-ingress --group-name EC2deployLinuxInstance --to-port 22 --ip-protocol tcp --cidr-ip 0.0.0.0/0 --from-port 22
aws ec2 authorize-security-group-ingress --group-name EC2deployLinuxInstance --to-port -1 --ip-protocol icmp --cidr-ip 0.0.0.0/0 --from-port 8

#deploy EC2 t2-micro instance
aws ec2 run-instances \
  --image-id ami-00d5e377dd7fad751 \
  --key-name id_rsa \
  --count 1 \
  --instance-type t2.micro \
  --security-groups EC2deployLinuxInstance > /dev/null

#filter out ID of our created e2 instance
instanceID=$(aws ec2 describe-instances --filters Name=instance.group-name,Values=EC2deployLinuxInstance --query 'Reservations[*].Instances[*].[InstanceId]' --output text)

#filter out the attached root volume
volumeID=$(aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instanceID --query 'Volumes[*].[VolumeId]' --output text)

#change volume size of created ec2 instance
aws ec2 modify-volume --size 100 --volume-id $volumeID

#define a benchmarking cronjob with command 
# */30 * * * * ./bench.sh >> tmp/aws-result.csv 
#in file cronjob.txt and execute it with 
#crontab cronjob.txt
#remove cronjob after 2 days with 
#crontab -r
