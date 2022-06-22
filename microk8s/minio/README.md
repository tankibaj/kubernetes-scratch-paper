- Add the Helm Repository:
    ```bash
    helm repo add minio https://charts.min.io/
    ```
<br/>

- Verify that you have access to the chart:
    ```bash
    helm search repo minio/minio --versions
    ```
<br/>

- Set the desire chart version
    ```bash
    HELM_CHART_VERSION=4.0.2
    ```
<br/>

- Download default values.yaml of chart
    ```bash
    helm show values minio/minio --version ${HELM_CHART_VERSION} > default-values.yaml
    ```
<br/>

- Set the desire namespace of helm deployment
    ```bash
    HELM_NAMESPACE=minio
    ```
<br/>

- Deploy the helm chart
    ```bash
    helm upgrade --install minio minio/minio --version ${HELM_CHART_VERSION} --create-namespace --namespace ${HELM_NAMESPACE}  --values values.yaml
    ```

<br/>

- Uninstall
    ```bash
    helm uninstall minio
    kubectl delete ns minio --force
    ```