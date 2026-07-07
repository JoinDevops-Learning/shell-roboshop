#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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

cp mongodb.repo /etc/yum.repos.d/mongodb.repo 
VALIDATE $? "Copying mongodb.repo"

dnf install mongodb-org -y
VALIDATE $? "Installing mongodb-org"

systemctl enable mongod
VALIDATE $? "Enabling mongod service"

systemctl start mongod
VALIDATE $? "Starting mongod service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "allowing mongodb to listen on all IP addresses"
systemctl restart mongod
VALIDATE $? "restarting mongod service"