# 🧑🏼‍🔬 Your Personal Kubernetes Sandbox 🧑🏼‍🔬
### 🤔 Why This Sandbox?  
For me, trying out new things in Kubernetes has always been a bit of a hassle. I’m a hands-on kind of person — I want to SEE how things work, experiment with them, and yes, sometimes even break them to understand their limits. If you’re like me, this sandbox is the perfect playground. It’s designed to help you dive right in, skip the tedious setup, and start exploring tools like `vault`, `argocd`, or `crossplane` in no time.

### 🚧 Under Development 🚧
This project is still a work in progress. The ultimate goal is to have all tools running with a minimal configuration, showcasing their functionality in a practical way. For example, deploying two sample applications with ArgoCD or creating a new group in GitLab via Crossplane. 

Your feedback and suggestions are highly appreciated! If you have ideas for improvements or additional use cases, feel free to contribute or open an issue in the repository. Together, we can make this sandbox even better! 🚀

### ⚠️ Warning
This project is for **testing purposes only**. It is not intended for production use. 

### 🔥💻🔥 Resources
Running this setup may consume **significant system resources**. The exact resource requirements depend on the choice of applications to deploy, but enabling all options simultaneously is **not recommended**, even on a high-performance machine like a M4 Mac with 24GB of RAM (*I'm speaking out of experience* 😉). By default, the cluster deploys one control-plane and one worker node using `traefik` as the ingress controller, and no applications are installed initially. All deployments are installed via Helm.

## 🛠️ Setup
Run the initial setup script:

```sh
sh initial-setup.sh [OPTIONS]
```

This script sets up the environment and allows you to specify which applications to deploy using CLI arguments. 

If the required CLI tools (e.g., `k3d`, `helm`) are not already installed, the script will automatically install them. Currently, all installations are performed using `brew` and `curl`, which means this setup does not support windows environments at this time (yes, `brew` actually runs on linux 🤯). By default, no applications are installed. Use the following options to customize the deployment:

| Option           | Description                              |
|-------------------|------------------------------------------|
| `--argocd`       | Deploys ArgoCD to the cluster.           |
| `--vault`        | Deploys Vault to the cluster.            |
| `--prometheus`   | Deploys Prometheus to the cluster.       |
| `--crossplane`   | Deploys Crossplane to the cluster.       |
| `...`            | `[...]`                                 |
| `--help`         | See overview of options.                |


For example, to deploy ArgoCD and Crossplane, run:

```sh
sh initial-setup.sh --argocd --crossplane
```

### What the Script Does:
* **k3s Cluster Creation:**
  * Ensures [k3d](https://k3d.io/stable/), a lightweight wrapper to run [k3s](https://github.com/k3s-io/k3s) in Docker, is installed and creates a cluster named `kubernetes-sandbox` using a custom configuration (`clusters/sandbox-cluster.yaml`).
  * Deploys one control-plane and one worker node.
  * Waits until all cluster nodes are ready.
* **Application Deployment (Optional):**
  * Installs selected applications (e.g., `argocd`, `vault`, `prometheus`) using `helm install [...]`.
  * Configures ingress resources for `traefik` to expose dashboards and services under a custom domain (see below ⬇️).
* **Access Information:**
  * For tools with a login (like `argocd` or `gitlab`) the initial admin credentials for deployed applications.

### `/etc/hosts` Entries

To access the services in your browser, you need to add the following entries to your `/etc/hosts` file. These entries are required if you activate the corresponding applications during setup. You only need the entries for the applications which you actually install:

```plaintext
127.0.0.1 argocd.local
127.0.0.1 prometheus.local
127.0.0.1 vault.local
127.0.0.1 crossplane.local
127.0.0.1 gitlab.local
```

Without these entries, the dashboards and services will _not_ be accessible via the provided URLs.

Access the dashboards in your browser:
- 🌐 **ArgoCD:** [http://argocd.local:8080](http://argocd.local:8080)
- 📊 **Prometheus:** [http://prometheus.local:8080](http://prometheus.local:8080)
- 🔐 **Vault:** [http://vault.local:8080](http://vault.local:8080)
- 🛠️ **Crossplane:** [http://crossplane.local:8080](http://crossplane.local:8080)


## 🧹 Teardown
To remove the k3s environment and clean up resources, run:

```bash
sh teardown.sh
```

This script deletes the k3s cluster and all associated resources. Don't forget to remove the entries from your `/etc/hosts` file!

## 🛠️ Troubleshooting

* **Dashboard Unreachable:**
    * Ensure you have added the correct entry in your `/etc/hosts` file.

* **Resource Issues or Pending Pods:**
    * Check node status and logs using:

        ```bash
        kubectl get nodes
        kubectl get pods -n <namespace>
        kubectl logs -n <namespace> <pod-name>
        ```

* **Image Pull Error Due to Unknown Authorities:**
    * Review this discussion for potential solutions: [k3d Discussion #535](https://github.com/k3d-io/k3d/discussions/535#discussioncomment-474982)

* **Helm or k3d Not Found:**
    * The setup script installs missing tools automatically. Verify your `PATH` settings if issues persist.

## 🤝 Contributing
Feel free to fork this repository and contribute improvements or additional app deployments. Pull requests are welcome!

## 🙌 Credit
The ArgoCD part of this sandbox was inspired by [this guide](https://www.arthurkoziel.com/setting-up-argocd-with-helm/).
