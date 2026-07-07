#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$(pwd)
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
VALIDATE $? "Disabling nodejs module"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
VALIDATE $? "Enabling nodejs module"

dnf install nodejs -y &>> $LOGS_FILE
VALIDATE $? "Installing nodejs"     

if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
VALIDATE $? "Creating roboshop system user"
else
    echo -e "$Y roboshop system user already exists $N" | tee -a $LOGS_FILE
fi

mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
VALIDATE $? "downloading cart code"
rm -rf /app/*
VALIDATE $? "Cleaning /app directory"

cd /app 
unzip /tmp/cart.zip
VALIDATE $? "downloading cart code"

cd /app 
VALIDATE $? "Changing directory to /app"

rm -rf /app/*
VALIDATE $? "Cleaning /app directory"

unzip /tmp/user.zip &>> $LOGS_FILE
VALIDATE $? "Extracting user code"

npm install &>> $LOGS_FILE
VALIDATE $? "Installing npm dependencies"

cp ${SCRIPT_DIR}/user.service /etc/systemd/system/user.service &>> $LOGS_FILE
VALIDATE $? "created systemctl service"

systemctl daemon-reload 
systemctl enable cart &>> $LOGS_FILE
systemctl start cart 
VALIDATE $? "Starting cart  service"