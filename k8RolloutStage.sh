#!/bin/bash

#k8s-deployment-rollout-status.sh

sleep 60s

if [[ $(kubectl -n default rollout status deploy ${DEPLOYMENT_NAME} --timeout 5s) != *"successfully rolled out"* ]]; 
then     
	echo "Deployment ${DEPLOYMENT_NAME} Rollout has Failed"
    kubectl -n default rollout undo deploy ${DEPLOYMENT_NAME}
    exit 1;
else
	echo "Deployment ${DEPLOYMENT_NAME} Rollout is Success"
fi

kubectl -n default rollout restart deploy ${DEPLOYMENT_NAME}