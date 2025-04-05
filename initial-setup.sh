#!/bin/bash
set -e

# Default values for flags
ARGO_ENABLED=false
CROSSPLANE_ENABLED=false
GITLAB_ENABLED=false
VAULT_ENABLED=false
HARBOR_ENABLED=false

# Display help message
function show_help() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  --argo         Enable ArgoCD"
  echo "  --crossplane   Enable Crossplane"
  echo "  --gitlab       Enable GitLab"
  echo "  --vault        Enable Vault (OpenBao)"
  echo "  --harbor       Enable Harbor"
  echo "  --help         Show this help message and exit"
  echo
  echo "Example:"
  echo "  $0 --argo --crossplane"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --argo)
      ARGO_ENABLED=true
      shift
      ;;
    --crossplane)
      CROSSPLANE_ENABLED=true
      shift
      ;;
    --gitlab)
      GITLAB_ENABLED=true
      shift
      ;;
    --vault)
      VAULT_ENABLED=true
      shift
      ;;
    --harbor)
      HARBOR_ENABLED=true
      shift
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo "Invalid option: $1"
      show_help
      exit 1
      ;;
  esac
done

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
    echo "Creating k3s cluster with custom configuration..."
    k3d cluster create $CLUSTER_NAME --config clusters/sandbox-cluster.yaml

    echo "Waiting for cluster nodes to be ready..."
    kubectl wait --for=condition=Ready node --all --timeout=240s
fi

# Check if ArgoCD setup is enabled
if [ "${ARGO_ENABLED}" == "true" ]; then
  # Install ArgoCD CLI
  if ! command -v argocd &> /dev/null
  then
    echo "argocd-cli not found, installing..."
    brew install argocd
  fi

  # Deploy ArgoCD with Helm
  if helm status argocd --namespace argocd > /dev/null 2>&1; then
    echo "ArgoCD is already installed, skipping deployment."
  else
    helm repo add argocd https://argoproj.github.io/argo-helm
    helm dep update charts/argocd/
    echo "Deploying ArgoCD..."
    helm install argocd charts/argocd/ -f charts/argocd/values.yaml --namespace argocd --create-namespace
  fi

  # Wait for ArgoCD server to be ready
  echo "Waiting for ArgoCD pods to become available..."
  kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=120s

  # Retrieve ArgoCD admin password
  echo "ArgoCD admin password:"
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  echo
else
  echo "ArgoCD setup is disabled. Skipping ArgoCD installation and configuration."
fi

if [ "${CROSSPLANE_ENABLED}" == "true" ]; then
  # Deploy Crossplane with Helm
  if helm status crossplane --namespace crossplane > /dev/null 2>&1; then
    echo "Crossplane is already installed, skipping deployment."
  else
    echo "Installing Crossplane with helm..."
    helm repo add crossplane-stable https://charts.crossplane.io/stable
    helm repo update
    helm install crossplane \
    --namespace crossplane-system \
    --create-namespace crossplane-stable/crossplane
  fi

  # Wait for Crossplane server to be ready
  echo "Waiting for Crossplane pods to become available..."
  kubectl wait --for=condition=Available deployment/crossplane -n crossplane-system --timeout=120s
else
  echo "Crossplane setup is disabled. Skipping Crossplane installation."
fi

if [ "${GITLAB_ENABLED}" == "true" ]; then
  echo "GitLab setup is enabled. Installing GitLab..."
  # Deploy GitLab with Helm
  if helm status gitlab --namespace gitlab > /dev/null 2>&1; then
    echo "GitLab is already installed, skipping deployment."
  else
    echo "Installing GitLab with helm..."
    helm repo add gitlab https://charts.gitlab.io
    helm repo update
    helm install gitlab gitlab/gitlab \
    --namespace gitlab \
    --create-namespace \
    -f charts/gitlab/values.yaml

    # Wait for GitLab pods to become available
    echo "Waiting for GitLab pods to become available..."
    kubectl wait --for=condition=Available deployment/gitlab-webservice-default -n gitlab --timeout=120s

    # Retrieve GitLab admin password
    echo "GitLab admin password:"
    kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d
    echo
  fi
else
  echo "GitLab setup is disabled. Skipping GitLab installation."
fi

if [ "${VAULT_ENABLED}" == "true" ]; then
  echo "Vault (we use openbao) setup is enabled. Installing OpenBao..."
  # Deploy OpenBao with Helm
  if helm status openbao --namespace openbao > /dev/null 2>&1; then
    echo "OpenBao is already installed, skipping deployment."
  else
    echo "Installing OpenBao with helm..."
    helm repo add openbao https://openbao.github.io/charts
    helm repo update
    helm install openbao openbao/openbao \
    --namespace openbao \
    --create-namespace \
    -f charts/openbao/values.yaml

    # Wait for OpenBao pods to become available
    echo "Waiting for OpenBao pods to become available..."
    kubectl wait --for=condition=Available deployment/openbao -n openbao --timeout=120s
  fi
else
  echo "Vault (we use openbao) setup is disabled. Skipping OpenBao installation."
fi

if [ "${HARBOR_ENABLED}" == "true" ]; then
  echo "Harbor setup is enabled. Installing Harbor..."
  # Deploy Harbor with Helm
  if helm status harbor --namespace harbor > /dev/null 2>&1; then
    echo "Harbor is already installed, skipping deployment."
  else
    echo "Installing Harbor with helm..."
    helm repo add harbor https://helm.goharbor.io
    helm repo update
    helm install harbor harbor/harbor \
    --namespace harbor \
    --create-namespace \
    -f charts/harbor/values.yaml

    # Wait for Harbor pods to become available
    echo "Waiting for Harbor pods to become available..."
    kubectl wait --for=condition=Available deployment/harbor-core -n harbor --timeout=120s
  fi
else
  echo "Harbor setup is disabled. Skipping Harbor installation."
fi

echo "k3s setup complete!"
