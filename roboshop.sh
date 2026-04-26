#!/bin/bash

SG_ID="sg-0075bb69cff1075c4" #Should replace with your ID
AMI_ID="ami-0220d79f3f480ecf5" #Should replace with your AMI ID

for instance in $@
do
    instance_id =  $( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceID' \
    --output text )

    if [ $instace == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
    fi
done
