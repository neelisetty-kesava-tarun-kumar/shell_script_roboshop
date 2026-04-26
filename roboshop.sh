#!/bin/bash

SG_ID="sg-0075bb69cff1075c4" #Should replace with your ID
AMI_ID="ami-0220d79f3f480ecf5" #Should replace with your AMI ID
ZONE_ID="Z00664892VVKTE5BFORKG" #Should replace with your Hosted Zone ID
DOMAIN_NAME="kesavatarun.in" #Should replace with your domain name

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
        RECORD_NAME="$DOMAIN_NAME" # This will create a record name with the domain name of the frontend domain only like "domain_name.com" for the frontend instance.
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
        RECORD_NAME="$instance.$DOMAIN_NAME" # This will create a record name like "catalog.kesavatarun.in" for the catalog instance, and "user.kesavatarun.in" for the user instance, and so on. This way, we can easily access the instances using their respective domain names.
    fi

    echo "IP Address of $instance = $IP" # This will print the IP address of the instance in the terminal, which is useful for the user to know the IP address of the instance that has been created. This can be used for further configuration or troubleshooting if needed.

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating A record for '$instance'",
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$RECORD_NAME'",
                    "Type": "A",
                    "TTL": 300,
                    "ResourceRecords": [
                        {
                            "Value": "'$IP'"
                        }
                    ]
                }
            }
        ]
    }'
    
    echo "A record is updated for $instance with IP $IP" # This will print a message in the terminal indicating that the A record has been updated for the instance with the corresponding IP address. This is useful for the user to know that the script has successfully updated the DNS records for the instances.
done
