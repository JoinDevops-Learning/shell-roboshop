#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$(pwd)
MYSQL_HOST=mysql.balumahendradevops.online

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
VALIDATE $? "Installing maven"

id roboshop &>> $LOGS_FILE

if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
VALIDATE $? "Creating roboshop system user"
else
    echo -e "$Y roboshop system user already exists $N" | tee -a $LOGS_FILE
fi

mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "downloading shipping code"

cd /app
VALIDATE $? "Changing directory to /app"

rm -rf /app/*
VALIDATE $? "Cleaning /app directory"

unzip /tmp/shipping.zip &>> $LOGS_FILE
VALIDATE $? "Extracting shipping code"

mvn clean package &>> $LOGS_FILE
VALIDATE $? "Building shipping code"        

mv target/shipping-1.0.jar shipping.jar &>> $LOGS_FILE
VALIDATE $? "Renaming shipping jar file"

cp ${SCRIPT_DIR}/shipping.service /etc/systemd/system/shipping.service &>> $LOGS_FILE
VALIDATE $? "created systemctl service"

dnf install mysql -y  &>> $LOGS_FILE
VALIDATE $? "Installing mysql client"   

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
VALIDATE $? "Loading shipping schema to mysql"

systemctl daemon-reload
systemctl enable shipping 
systemctl start shipping &>> $LOGS_FILE
VALIDATE $? "Starting shipping service"
