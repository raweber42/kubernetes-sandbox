# k3s Lab Environment

This repository sets up a local k3s cluster with ArgoCD and Traefik for testing and development. It also deploys an app-of-apps that includes ArgoCD and Prometheus.

## Getting Started

### Setup
Run the initial setup script:

```sh
sh initial-setup.sh
```

This script performs the following actions:

* **k3s Cluster Creation:**
  * Checks for the existence of `k3d` and installs it if not found.
  * Creates a k3s cluster named `kubernetes-sandbox` using a custom configuration (`clusters/local-cluster.yaml`).
  * Waits until all cluster nodes are ready.
* **ArgoCD Installation:**
  * Installs the ArgoCD CLI (if not already installed, only works with `brew` for Linux/Mac).
  * Adds the ArgoCD Helm repository and updates dependencies.
  * Deploys ArgoCD using Helm into the `argocd` namespace.
  * Waits for the ArgoCD server pods to be available.
  * Deploys the App of Apps (currently containing ArgoCD and Prometheus) using Helm templating.
  * Exposes the ArgoCD dashboard via an Ingress resource configured for Traefik.
* **Access Information:**
  * The script prints the initial admin password for ArgoCD.
  * To access the dashboard without annoying port-forwarding, add an entry to your `/etc/hosts` file:

      ```lua
      127.0.0.1 argocd.local
      ```

  * Once added, access ArgoCD in your browser at: [http://argocd.local:8080](http://argocd.local:8080)
      * Username: `admin`
      * Password: (printed in the terminal)

### Teardown
To remove the k3s environment and clean up resources, run:

```bash
sh teardown.sh
```

This script will delete the k3s cluster and all associated resources, leaving your local system clean.

## Troubleshooting

* **ArgoCD Dashboard Unreachable:**
    * Ensure you have added the correct entry in your `/etc/hosts` file:

        ```lua
        127.0.0.1 argocd.local
        ```

* **Resource Issues or Pending Pods:**
    * Check node status and logs using:

        ```bash
        kubectl get nodes
        kubectl get pods -n argocd
        kubectl logs -n argocd <pod-name>
        ```

* **Helm or k3d Not Found:**
    * The setup script checks for these tools and installs them if missing. Verify your `PATH` settings if issues persist.

## Contributing
Feel free to fork this repository and contribute improvements or additional app deployments. Pull requests are welcome!

## Credit
This sandbox was inspired by [this guide]( https://www.arthurkoziel.com/setting-up-argocd-with-helm/).

