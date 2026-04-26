#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell_script_roboshop" # This variable is used to store the logs of the script in a specific folder, which is useful for troubleshooting and debugging purposes. The user can check the logs to see if there were any errors or issues during the execution of the script, and it can also be used to track the progress of the script. The user should ensure that they have the necessary permissions to create and write to this folder, and it is recommended to use a folder that is not easily accessible to unauthorized users for security reasons.
LOGS_FILE="$LOGS_FOLDER/$0.log"
R='\e[0;31m'
G='\e[0;32m'
Y='\e[0;33m'
N='\e[0m'
SCRIPT_DIR=$PWD
MYSQL_HOST="mysql.kesavatarun.in"

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

dnf install maven -y &>> $LOGS_FILE
VALIDATE $? "Installing Maven"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip
VALIDATE $? "Downloading shipping code"

cd /app 
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing the existing shipping code if exists"

unzip /tmp/shipping.zip &>> $LOGS_FILE
VALIDATE $? "Extracting or Unzip the shipping code"

cd /app 
mvn clean package &>> $LOGS_FILE
VALIDATE $? "Building the shipping code using maven"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Moving the shipping jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying systemctl service file for shipping"

dnf install mysql -y &>> $LOGS_FILE
VALIDATE $? "Installing MySQL Client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>> $LOGS_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>> $LOGS_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>> $LOGS_FILE
    VALIDATE $? "Inserting data into MySQL"
else
    echo -e "$Y cities database already exists, skipping data insertion into MySQL $N" | tee -a $LOGS_FILE
fi

systemctl enable shipping &>> $LOGS_FILE
systemctl start shipping
VALIDATE $? "Enabling and Starting shipping service"