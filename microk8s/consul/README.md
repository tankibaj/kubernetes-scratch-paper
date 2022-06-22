- Add the Helm Repository:
    ```bash
    helm repo add hashicorp https://helm.releases.hashicorp.com
    ```
<br/>

- Verify that you have access to the chart:
    ```bash
    helm search repo hashicorp/consul --versions
    ```
<br/>

- Set the desire chart version
    ```bash
    HELM_CHART_VERSION=0.45.0
    ```
<br/>

- Download default values.yaml of chart
    ```bash
    helm show values hashicorp/consul --version ${HELM_CHART_VERSION} > default-values.yaml
    ```
<br/>

- Set the desire namespace of helm deployment
    ```bash
    HELM_NAMESPACE=consul
    ```
<br/>

- Deploy the helm chart
    ```bash
    helm upgrade --install consul hashicorp/consul --version ${HELM_CHART_VERSION} --create-namespace --namespace ${HELM_NAMESPACE}  --values values.yaml
    ```
<br/>

- Viewing the Consul UI
    ```bash
    kubectl port-forward service/consul-server --namespace ${HELM_CHART_VERSION} 8500:8500
    ```
    Once the port is forwarded navigate to [https://localhost:8500](https://localhost:8500)

<br/>

- Uninstall
    ```bash
    helm uninstall consul
    kubectl delete ns consul --force
    ```