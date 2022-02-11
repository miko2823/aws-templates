#!/bin/sh


set -e

read -p 'Cluster Name: ' clustername
read -p 'VPC ID: ' vpcid
read -p 'Your AWS-Profile Name': profile

echo 'Thank you. Now start creating service-mesh...'

echo 'Add the eks-charts repository to Helm...'
helm repo add eks https://aws.github.io/eks-charts

echo 'Install the App Mesh Kubernetes custom resource definitions (CRD)...'
kubectl apply -k "https://github.com/aws/eks-charts/stable/appmesh-controller/crds?ref=master"

echo 'Create a Kubernetes namespace for the controller...'
kubectl create ns appmesh-system

echo 'Applying mesh...'
kubectl apply -f mesh.yaml

echo 'Create an IAM role, attach the AWSAppMeshFullAccess and AWSCloudMapFullAccess AWS managed policies to it, and bind it to the appmesh-controller Kubernetes service account. ..'
eksctl create iamserviceaccount \
    --cluster ${clustername} \
    --namespace appmesh-system \
    --name appmesh-controller \
    --attach-policy-arn  arn:aws:iam::aws:policy/AWSCloudMapFullAccess,arn:aws:iam::aws:policy/AWSAppMeshFullAccess \
    --override-existing-serviceaccounts \
    --approve \
    --profile $profile

echo 'Deploy the App Mesh controller...'
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=ap-northeast-1 \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller

echo 'Enable X-Ray Tracing...'
helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=ap-northeast-1 \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller \
    --set tracing.enabled=true \
    --set tracing.provider=x-ray

echo 'Create AWS Cloud Map namespace...'
aws servicediscovery create-private-dns-namespace \
    --name {YourCloudMap} \
    --vpc ${vpcid} \
    --profile $profile


echo 'Successfully deployed AWS App Mesh!!'
echo 'check your deployment by runnning `kubectl get deployment -n appmesh-system`'
