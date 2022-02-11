#!/bin/sh

# ArgoCD environment

set -e

read -p 'Have you installed argocd CLI? (y/n): '  cli_installed
if [ $cli_installed = "y" ]; then
    echo "Thank you."
else
    echo "Please install it from HomeBrew `brew install argocd`."
    exit 1;
fi

read -p 'Git Hub Token of  lisse-dev-manage: ' token
read -p 'Target Branch(develop/staging/master): ' branch
read -p 'Value.file Name: ' valuefile_name

echo 'Deploying ArgoCD...'
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo 'Connecting server...'
kubectl port-forward svc/argocd-server -n argocd 8080:443


export ARGO_DEFAULT_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Your default user password is ${ARGO_DEFAULT_PASSWORD}"

echo 'Please change your password...'
argocd login localhost:8080

echo 'Settings chart repository...'
argocd repocreds add {YourChartRepo} --username lisse-dev-manage --password $token

echo 'Adding application into ArgoCD...'
template=`cat "application.yaml" | sed "s/{{TARGET_BRANCH}}/$branch/g"`
echo "$template" | kubectl apply -f -

argocd app set {YourArgocdAppName} --values $valuefile_name

echo 'Done'
