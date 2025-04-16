# Install crossplane 

helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm install crossplane \
--namespace crossplane-system \
--create-namespace crossplane-stable/crossplane

# Install harbor

helm upgrade --install harbor harbor/harbor -f values.yaml --namespace harbor --create-namespace

