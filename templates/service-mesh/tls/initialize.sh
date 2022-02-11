#!/bin/sh
#####
# execute this after creaeting PCA to *.{CloudMapNameSpace}
#####

set -e

read -p 'AWS Account ID: ' account_id
read -p 'ACM Arn: ' acm_arn
read -p 'Cluster Name: ' clustername
read -p 'Your AWS-Profile Name: ' profile


echo 'Creating SA Policy...'
export account_id=$account_id
export acm_arn=$acm_arn
envsubst < sa-policy.json > my-sa-policy.json

aws iam create-policy \
    --policy-name EKSAppMeshSAPolicy \
    --policy-document file://my-sa-policy.json \
    --profile $profile
rm my-sa-policy.json

echo 'Creating SA...'
eksctl create iamserviceaccount \
    --cluster ${clustername} \
    --namespace app \
    --name app-sa \
    --attach-policy-arn arn:aws:iam::${account_id}:policy/EKSAppMeshSAPolicy \
    --override-existing-serviceaccounts \
    --approve \
    --profile $profile

eksctl create iamserviceaccount \
    --cluster ${clustername} \
    --namespace app \
    --name filereader \
    --attach-policy-arn arn:aws:iam::${account_id}:policy/EKSAppMeshSAPolicy \
    --override-existing-serviceaccounts \
    --approve \
    --profile $profile
