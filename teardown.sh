#!/bin/bash
set -e

# Define cluster name
CLUSTER_NAME="kubernetes-sandbox"

# Prompt user for confirmation
read -p "WARNING: This will delete the entire cluster '$CLUSTER_NAME' and all its resources. Are you sure you want to proceed? [y/N]: " CONFIRM
CONFIRM=${CONFIRM:-n}

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    # Delete k3s cluster
    echo "Deleting k3s cluster..."
    k3d cluster delete $CLUSTER_NAME
else
    echo "Operation canceled."
fi
