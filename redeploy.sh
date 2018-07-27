#!/bin/bash

# Create docker image, deploy to cluster
# Meant for debugging, not production


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$DIR/splunk-configured-docker"
sudo docker build -t custom-splunk:latest .
sudo docker tag custom-splunk:latest gcr.io/pantel-2decb/splunk
sudo docker login -u oauth2accesstoken -p "$(gcloud auth print-access-token)" https://gcr.io
sudo docker push gcr.io/pantel-2decb/splunk 
sudo docker logout gcr.io
cd ..  
#kubectl delete deployment splunk-forwarder
#kubectl apply -f splunk-deployment.yaml

