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

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/* 
VALIDATE $? "Removing the existing catalogue code if exists"

unzip /tmp/catalogue.zip &>> $LOGS_FILE 
VALIDATE $? "Extracting or Unzip the catalogue code"

npm install &>> $LOGS_FILE
VALIDATE $? "Installing NodeJS dependencies for catalogue"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying systemctl service file for catalogue"

systemctl daemon-reload
systemctl enable catalogue &>> $LOGS_FILE
systemctl start catalogue
VALIDATE $? "Starting catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongodb.repo
dnf install mongodb-mongosh -y &>> $LOGS_FILE
VALIDATE $? "Installing MongoDB Shell"

INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    #echo -e "$Y catalogue database does not exist, inserting the data into MongoDB $N" | tee -a $LOGS_FILE
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>> $LOGS_FILE
    VALIDATE $? "Inserting data into MongoDB"
else
    echo -e "$Y Catalogue database already exists, skipping data insertion into MongoDB $N" | tee -a $LOGS_FILE
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue service"