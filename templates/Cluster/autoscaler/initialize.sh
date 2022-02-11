#!/bin/sh

# In this script, we create Autoscaling settings.
# See details from https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html
# Cluster AutoScaling Version is in this link https://github.com/kubernetes/autoscaler/releases
# Select a compatible version to your Cluster

set -e

read -p 'AWS Account Id: ' account_id
read -p 'Cluster Name: ' clustername
read -p 'Cluster Autoscaler Version: ' cluster_autoscaler_version
read -p 'Your AWS Profile Name: ' profile

echo 'Installign Metrics Server...'
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml


echo 'Creating an IAM Autoscaling policy...'
aws iam create-policy \
    --policy-name AmazonEKSClusterAutoscalerPolicy \
    --policy-document file://policy.json \
    --profile $profile


echo 'Creating IamServiceAccount...'
eksctl create iamserviceaccount \
  --cluster=$clustername \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::$account_id:policy/AmazonEKSClusterAutoscalerPolicy \
  --override-existing-serviceaccounts \
  --approve \
  --profile $profile


echo 'Deploying the Cluster Autoscaler...'
export clustername=$clustername
envsubst < autoscaler.yaml > my_autoscaler.yaml
kubectl apply -f my_autoscaler.yaml
rm my_autoscaler.yaml


echo 'Patching the deployment...'
kubectl patch deployment cluster-autoscaler \
  -n kube-system \
  -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'

echo 'Setiing image version...'
kubectl set image deployment cluster-autoscaler \
  -n kube-system \
  cluster-autoscaler=k8s.gcr.io/autoscaling/cluster-autoscaler:$cluster_autoscaler_version

echo 'Done.'
