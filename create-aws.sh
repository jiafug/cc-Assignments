#!/bin/bash



#aws ec2 create-key-pair \
#--key-name id_rsa \
#--query 'id_rsa' \
#--output text > id_rsa.pub
ssh-keygen -t rsa -b 4096 -f ./id_rsa -C ec2-user -c ec2-user  #User and Username as Comment

#check for existing vpcs
listVPC=$(aws ec2 describe-vpcs --filters is-default=true --output text)
#$lineCount= wc –l vpc.json
#count the lines or check if "isDefault"=true exists
#if [[ !$lineCount -gt 7 ]]

#check if there is no default VPC
if [[ ! $listVPC = "\"IsDefault\": true" ]]
then
	#if there is no default VPC, create one
	aws ec2 create-default-vpc
fi




#upload the keyfile into kms
aws iam upload-ssh-public-key --user-name ec2-user --ssh-public-key-body file://id_rsa.pub

#if desired, we can create our own IAM role with the following command
#aws iam create-role --role-name EC2Assignment1 --assume-role-policy-document file://IAMPolicyAssignment1.json

#the following command creates a security-group, which has no entries
aws ec2 create-security-group --group-name EC2deployLinuxInstance --description "For launching a Linux Server"
#the following command sets an ingress rule to the created security-group. Every other port to access from outside is blocked
aws ec2 authorize-security-group-ingress --group-name EC2deployLinuxInstance --to-port 22 --ip-protocol tcp --cidr-ip 0.0.0.0/0 --from-port 22

aws ec2 run-instances \
  --image-id ami-id \
  --key-name id_rsa \
  --count 1 \
  --instance-type t2.large \
  --security-groups EC2deployLinuxInstance \
#   --iam-instance-profile Name=iam-instance-profile \

#to resize the attached root-volume, we first need to find the instanceID on which the volume is attached to, 
#therefore we create a list of instances which have the created security-grouped attached
instanceList=$(aws ec2 describe-instances --filters instance.group-name EC2deployLinuxInstance --query 'Reservations[*].Instances[*].{Instance:InstanceId}' --output text)
#after creating the list, we use the following commands to filter out instance ID
instanceID=$(grep "\"InstanceId\": \"" instanceList | grep -o "/^(.*?)\,\"/*")

#filter out the attached root volume
volumeList=$(aws ec2 describe-volumes --filters attachment.instance-id=$instanceID --query \"Volumes[*].{ID:VolumeId}\" --output text)

$volumeID=$(grep "\"InstanceId\": \"" volumeList | grep -o "/^(.*?)\,\"/*")
#the following command changes the size of the volume attached to the created ec2 instance
aws ec2 modify-volume --size 100 --volume-id $volumeID

