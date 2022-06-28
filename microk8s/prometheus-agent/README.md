- Add the Helm Repository:
    ```bash
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    ```
<br/>

- Verify that you have access to the chart:
    ```bash
    helm search repo prometheus-community/kube-prometheus-stack --versions
    ```
<br/>

- Set the desire chart version
    ```bash
    HELM_CHART_VERSION=35.5.1
    ```
<br/>

- Download default values.yaml of chart
    ```bash
    helm show values prometheus-community/kube-prometheus-stack --version ${HELM_CHART_VERSION} > values-default-v${HELM_CHART_VERSION}.yaml
    ```
<br/>

- Set the desire namespace of helm deployment
    ```bash
    HELM_NAMESPACE=kube-prometheus
    ```
<br/>

- Deploy the helm chart
    ```bash
    helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack --version ${HELM_CHART_VERSION} --create-namespace --namespace ${HELM_NAMESPACE} --values values-v${HELM_CHART_VERSION}.yaml
    ```

<br/>

- Uninstall
    ```bash
    helm uninstall kube-prometheus
    kubectl delete ns kube-prometheus --force
    ```