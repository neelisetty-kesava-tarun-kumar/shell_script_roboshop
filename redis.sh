#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell_script_roboshop" # This variable is used to store the logs of the script in a specific folder, which is useful for troubleshooting and debugging purposes. The user can check the logs to see if there were any errors or issues during the execution of the script, and it can also be used to track the progress of the script. The user should ensure that they have the necessary permissions to create and write to this folder, and it is recommended to use a folder that is not easily accessible to unauthorized users for security reasons.
LOGS_FILE="$LOGS_FOLDER/$0.log"
R='\e[0;31m'
G='\e[0;32m'
Y='\e[0;33m'
N='\e[0m'
SCRIPT_DIR=$PWD
MONGODB_HOST="mongodb.kesavatarun.in" # This variable is used to store the hostname of the MongoDB instance, which is used to connect to the MongoDB database and execute the master-data.js script. The user should replace this variable with the actual hostname of their MongoDB instance, which can be obtained from the AWS EC2 console or by using the AWS CLI. This is important for the script to work correctly and to ensure that the data is inserted into the correct MongoDB instance. The user should also ensure that the MongoDB instance is running and accessible from the machine where this script is being executed, and that the necessary ports are open for communication between the script and the MongoDB instance.

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1 
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable redis -y &>> $LOGS_FILE
dnf module enable redis:7 -y &>> $LOGS_FILE
VALIDATE $? "Enabling Redis 7 module"

dnf install redis -y &>> $LOGS_FILE
VALIDATE $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>> $LOGS_FILE
VALIDATE $? "Updating Redis configuration to allow remote connections and disable protected mode"

systemctl enable redis  &>> $LOGS_FILE
systemctl start redis 
VALIDATE $? "Enable and Starting Redis service"
