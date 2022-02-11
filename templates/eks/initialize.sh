#!/bin/sh

set -e

read -p 'AWS Account(number): ' awsaccount
read -p 'EKS Cluster Name: ' clustername
read -p 'Your AWS-Profile Name: ' profile

echo 'setting kubeconfig context...'
aws eks update-kubeconfig \
  --region ap-northeast-1 \
  --name $clustername \
  --profile $profile

echo 'switching kubeconfig context...'
kubectl config use-context arn:aws:eks:ap-northeast-1:$awsaccount:cluster/$clustername

echo 'creating OICD Provider...'
eksctl utils associate-iam-oidc-provider --cluster $clustername --approve --profile $profile

echo 'enabling controle plane logging...'
aws eks update-cluster-config \
    --region ap-northeast-1 \
    --name $clustername \
    --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}' \
    --profile $profile

echo 'create namespace...'
kubectl apply -f namespace.yaml

echo 'create job sa...'
aws iam create-policy \
    --policy-name SecretManagerReadOnlyPolicy \
    --policy-document file://job-policy.json \
    --profile $profile

eksctl create iamserviceaccount \
    --name cronjob \
    --namespace jobs \
    --cluster $clustername \
    --attach-policy-arn "arn:aws:iam::${awsaccount}:policy/SecretManagerReadOnlyPolicy" \
    --approve \
    --override-existing-serviceaccounts \
    --profile $profile

echo 'Done.'
