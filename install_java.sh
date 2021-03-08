#! /bin/bash
logfile=/tmp/initialize.log
sudo yum install -y java 1> $logfile 2>> $logfile
now=$(date +"%Y-%m-%d %H:%M:%S")
echo "$now: Java installed!" >> $logfile
