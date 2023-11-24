#!/bin/bash -e
hostnamectl

echo ''
read -p "show CPU spec... " nil
lscpu

echo ''
read -p "show ram in MB... " nil
free -m

echo ''
read -p "show disk... " nil
df -h

echo ''
read -p "show mysql version... " nil
mysql --version

