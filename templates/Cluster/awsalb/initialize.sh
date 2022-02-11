#!/bin/sh

set -e

read -p 'AWS Account ID: ' account_id
read -p 'Cluster Name: ' cluster_name
read -p 'Your AWS-Profile Name: ' profile

echo 'creating a AWSLBC Policy...'
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://cluster-autoscaler-policy.json \
    --profile $profile

echo 'creating service account...'
eksctl create iamserviceaccount \
  --cluster=$cluster_name \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$account_id:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve \
  --profile $profile

echo 'deploying cert-manager...'
kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.0.2/cert-manager.yaml

echo 'deploying AWS LBC...'
export cluster_name=$cluster_name
envsubst < v2_3_0_full.yaml > my_v2_3_0_full.yaml

kubectl apply -f my_v2_3_0_full.yaml
rm my_v2_3_0_full.yaml
