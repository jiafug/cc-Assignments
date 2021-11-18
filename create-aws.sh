#!/bin/bash



#aws ec2 create-key-pair \
#--key-name id_rsa \
#--query 'id_rsa' \
#--output text > id_rsa.pub
#User and Username as Comment

ssh-keygen -t rsa -f id_rsa -C user -P ""

# read the ssh key
key=$(<id_rsa.pub)

# array of splitted key; split on space
#array=(${key// / })

# get the user
#user=${array[2]}

# build a gcp compliant ssh key
#newKey="${user}: ${key}"

# write new key to file
#echo $newKey >id_rsa.pub


#check for existing vpcs
listVPC=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[*].[IsDefault]' --output text)
#$lineCount= wc –l vpc.json
#count the lines or check if "isDefault"=true exists
#if [[ !$lineCount -gt 7 ]]

#check if there is no default VPC
if [[ ! $listVPC = "True" ]]
then
	#if there is no default VPC, create one
	aws ec2 create-default-vpc
fi




#upload the keyfile into kms
#aws iam upload-ssh-public-key --user-name AWSCLI --ssh-public-key-body file://id_rsa.pub
aws ec2 import-key-pair --key-name id_rsa --public-key-material fileb://id_rsa.pub

#if desired, we can create our own IAM role with the following command
#aws iam create-role --role-name EC2Assignment1 --assume-role-policy-document file://IAMPolicyAssignment1.json

#the following command creates a security-group, which has no entries
aws ec2 create-security-group --group-name EC2deployLinuxInstance --description "For launching a Linux Server"
#the following command sets an ingress rule to the created security-group. Every other port to access from outside is blocked
aws ec2 authorize-security-group-ingress --group-name EC2deployLinuxInstance --to-port 22 --ip-protocol tcp --cidr-ip 0.0.0.0/0 --from-port 22
aws ec2 authorize-security-group-ingress --group-name EC2deployLinuxInstance --to-port -1 --ip-protocol icmp --cidr-ip 0.0.0.0/0 --from-port 8

aws ec2 run-instances \
  --image-id ami-00d5e377dd7fad751 \
  --key-name id_rsa \
  --count 1 \
  --instance-type t2.micro \
  --security-groups EC2deployLinuxInstance > /dev/null
#   --iam-instance-profile Name=iam-instance-profile \

echo "test"

#to resize the attached root-volume, we first need to find the instanceID on which the volume is attached to, 
#therefore we create a list of instances which have the created security-grouped attached
instanceID=$(aws ec2 describe-instances --filters Name=instance.group-name,Values=EC2deployLinuxInstance --query 'Reservations[*].Instances[*].[InstanceId]' --output text)
#after creating the list, we use the following commands to filter out instance ID
#instanceID=$(grep "\"InstanceId\": \"" instanceList | grep -o "/^(.*?)\,\"/*")
echo $instanceID
#filter out the attached root volume
volumeID=$(aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instanceID --query 'Volumes[*].[VolumeId]' --output text)

#$volumeID=$(grep "\"InstanceId\": \"" volumeList | grep -o "/^(.*?)\,\"/*")
#the following command changes the size of the volume attached to the created ec2 instance
aws ec2 modify-volume --size 100 --volume-id $volumeID
