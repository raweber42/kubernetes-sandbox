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


helm repo add argo-cd https://argoproj.github.io/argo-helm
helm dep update charts/argo-cd/



# # Deploy ArgoCD
echo "Deploying ArgoCD..."
helm install argo-cd charts/argo-cd/ --namespace argocd --create-namespace

# # Wait for ArgoCD server to be ready
# kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=120s

# # Expose ArgoCD for external access
# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# # Retrieve ArgoCD admin password
# echo "ArgoCD admin password:"
# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
# echo

echo "k3s setup complete!"
