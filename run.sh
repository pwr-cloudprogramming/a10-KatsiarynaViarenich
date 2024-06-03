#!/bin/bash
apt update
apt-get -y install openjdk-17-jdk maven 
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
su - ubuntu

git clone https://github.com/pwr-cloudprogramming/a5-KatsiarynaViarenich.git
cd ./a5-KatsiarynaViarenich/backend

IP_ADDRESS=$(curl -s ifconfig.me)
cd src/main/resources/ && echo "ip_address=$IP_ADDRESS" > application.properties && cd ../../..
mvn package
docker build -t backend .
docker run -d -p 8080:8080 --name backend-container backend

cd ../frontend
cd js && sed -i "1s/.*/const url = 'http:\/\/$IP_ADDRESS:8080';/" socket_js.js && cd ..
docker build -t frontend .
docker run -d -p 8081:3000 --name frontend-container frontend

cd frontend-client-react
docker build -t react-frontend
docker run -d - p 8082:8082 --name react-frontend-container react-frontend 