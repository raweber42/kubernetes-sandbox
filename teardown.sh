#!/bin/bash
set -e

# Define cluster name
CLUSTER_NAME="kubernetes-sandbox"

# Delete k3s cluster
echo "Deleting k3s cluster..."
k3d cluster delete $CLUSTER_NAME
