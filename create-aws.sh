#!/bin/bash



#aws ec2 create-key-pair \
#--key-name id_rsa \
#--query 'id_rsa' \
#--output text > id_rsa.pub
ssh-keygen -t rsa -b 4096 -f ./id_rsa -C ec2-user -c ec2-user  #User and Username as Comment

#check for existing vpcs
aws ec2 describe-vpcs --filters is-default=true >> vpc.json
$lineCount= wc –l vpc.json
#zähle Zeilen oder prüfe ob "isDefault"=true vorkommt
if [[ !$lineCount -gt 7 ]]
then
	aws ec2 create-default-vpc
fi




#upload the keyfile into kms
aws iam upload-ssh-public-key --user-name ec2-user --ssh-public-key-body file://id_rsa.pub

#IAMPolicyAssignment1.json müssen wir noch erstellen
#aws iam create-role --role-name EC2Assignment1 --assume-role-policy-document file://IAMPolicyAssignment1.json

aws ec2 create-security-group --group-name EC2deployLinuxInstance --description "For launching a Linux Server"
aws ec2 authorize-security-group-ingress --group-name EC2deployLinuxInstance --to-port 22 --ip-protocol tcp --cidr-ip 0.0.0.0/0 --from-port 22

aws ec2 run-instances \
  --image-id ami-id \
  --key-name id_rsa \
  --count 1 \
  --instance-type t2.large \
  --security-groups EC2deployLinuxInstance \
  >> ec2.json
#   --iam-instance-profile Name=iam-instance-profile \
#filtern der Instance ID
$instanceID=...............

#Filtern des Volumes 
aws ec2 describe-volumes --filters attachment.instance-id=$instanceID

$volumeID=................

aws ec2 modify-volume --size 100 --volume-id $volumeID

