#!/bin/bash

SG_ID="sg-0075bb69cff1075c4" #Should replace with your ID
AMI_ID="ami-0220d79f3f480ecf5" #Should replace with your AMI ID

for instance in $@
do
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then # "$instance" is safe to use, It will not break the code, Example: If the instance name is my app without the brackets, it will not work, but if we use "$instance", it will work fine. The user should be aware of this when naming the instances, It is recommended to use names without spaces or special characters to avoid any issues. So that the instances will be created successfully and the script will work as expected.
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
    fi

    echo "IP Address of $instance = $IP"
done
