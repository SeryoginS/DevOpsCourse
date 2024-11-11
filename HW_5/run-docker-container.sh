#!/bin/bash

IMAGE_NAME="serjseryogin/my-nginx-devops:v1"
CONTAINER_NAME="nginx-devops-container"

echo "Pulling Docker image: $IMAGE_NAME"
docker pull $IMAGE_NAME

echo "Running the container in the background on port 80"
docker run -d -p 80:80 --name $CONTAINER_NAME $IMAGE_NAME

if [ $? -eq 0 ]; then
    echo "Container $CONTAINER_NAME is now running on port 80."
else
    echo "Failed to run the container."
fi
