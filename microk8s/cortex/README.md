- Add the Helm Repository:
    ```bash
      helm repo add cortex-helm https://cortexproject.github.io/cortex-helm-chart
    ```
<br/>

- Verify that you have access to the chart:
    ```bash
    helm search repo cortex-helm/cortex --versions
    ```
<br/>

- Set the desire chart version
    ```bash
    HELM_CHART_VERSION=1.6.0
    ```
<br/>

- Download default values.yaml of chart
    ```bash
    helm show values cortex-helm/cortex --version ${HELM_CHART_VERSION} > values-default-v${HELM_CHART_VERSION}.yaml
    ```
<br/>

- Set the desire namespace of helm deployment
    ```bash
    HELM_NAMESPACE=cortex
    ```
<br/>

- Deploy the helm chart
    ```bash
    helm upgrade --install cortex cortex-helm/cortex --version ${HELM_CHART_VERSION} --create-namespace --namespace ${HELM_NAMESPACE} --values values-v${HELM_CHART_VERSION}.yaml
    ```

<br/>

- Uninstall
    ```bash
    helm uninstall cortex
    kubectl delete ns cortex --force
    ```