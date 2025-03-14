#!/bin/bash
set -e

# Define cluster name
CLUSTER_NAME="kubernetes-sandbox"

# Check if k3d is installed
if ! command -v k3d &> /dev/null
then
    echo "k3d not found, installing..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Create k3s cluster using k3d and our config file
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo "Cluster $CLUSTER_NAME already exists. Skipping creation."
else
    echo "Creating k3s cluster..."
    k3d cluster create $CLUSTER_NAME --config clusters/local-cluster.yaml

    echo "Waiting for cluster nodes to be ready..."
    kubectl wait --for=condition=Ready node --all --timeout=120s
fi

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready node --all --timeout=240s

# Install ArgoCD CLI
if ! command -v argocd &> /dev/null
then
    echo "argocd-cli not found, installing..."
    brew install argocd
fi

helm repo add argocd https://argoproj.github.io/argo-helm
helm dep update charts/argocd/

# Deploy ArgoCD with Helm
if helm status argocd --namespace argocd > /dev/null 2>&1; then
  echo "ArgoCD is already installed, skipping deployment."
else
  echo "Deploying ArgoCD..."
  helm install argocd charts/argocd/ -f charts/argocd/values.yaml --namespace argocd --create-namespace
fi

# Wait for ArgoCD server to be ready
echo "Waiting for ArgoCD pods to become available..."
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=120s

# Deploy app of apps for ArgoCDresources-finalizer.argocd.argoproj.io
helm template charts/base/ | kubectl apply -f -

# Retrieve ArgoCD admin password
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

echo "k3s setup complete!"
