#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell_script_roboshop" # This variable is used to store the logs of the script in a specific folder, which is useful for troubleshooting and debugging purposes. The user can check the logs to see if there were any errors or issues during the execution of the script, and it can also be used to track the progress of the script. The user should ensure that they have the necessary permissions to create and write to this folder, and it is recommended to use a folder that is not easily accessible to unauthorized users for security reasons.
LOGS_FILE="$LOGS_FOLDER/$0.log"
R='\e[0;31m'
G='\e[0;32m'
Y='\e[0;33m'
N='\e[0m'

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

dnf module disable nodejs -y &>> $LOGS_FILE
VALIDATE $? "Disabling NodeJS module"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
VALIDATE $? "Enabling NodeJS 20 module"

dnf install nodejs -y &>> $LOGS_FILE
VALIDATE $? "Installing NodeJS"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
    VALIDATE $? "Creating system user for roboshop"
else
    echo -e "$Y User roboshop already exists, skipping user creation $N" | tee -a $LOGS_FILE
fi

mkdir -p /app 
VALIDATE $? "Creating directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGS_FILE
VALIDATE $? "Downloading catalogue code"

