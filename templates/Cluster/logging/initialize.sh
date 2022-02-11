#!/bin/sh

# In this script, we create EKS logging settings with EFK formation.
# https://www.eksworkshop.com/intermediate/230_logging/
# Before executing this script, run cloudformation stack with logging.yaml and
# check ES domain has ready status.

set -e

read -p 'Cluster Name: ' clustername
read -p 'Your AWS Profile Name: ' profile

echo 'creaeting namespace...'
kubectl create namespace logging

echo 'creating sa for fluentbit to access ES...'
eksctl create iamserviceaccount \
    --name fluent-bit \
    --namespace logging \
    --cluster $clustername \
    --attach-policy-arn "arn:aws:iam::aws:policy/CloudWatchFullAccess" \
    --approve \
    --override-existing-serviceaccounts \
    --profile $profile

echo 'Deploy daemonset...'
kubectl apply -f fluentbit_cloudwatch.yaml

echo 'Done.'
