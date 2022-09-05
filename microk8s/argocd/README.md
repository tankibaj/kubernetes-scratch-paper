- Add the Helm Repository:
    ```bash
      helm repo add argo https://argoproj.github.io/argo-helm
    ```
<br/>

- Verify that you have access to the chart:
    ```bash
    helm search repo argo/argo-cd --versions
    ```
<br/>

- Set the desire chart version
    ```bash
    HELM_CHART_VERSION=5.4.0
    ```
<br/>

- Download default values.yaml of chart
    ```bash
    helm show values argo/argo-cd --version ${HELM_CHART_VERSION} > values-default-v${HELM_CHART_VERSION}.yaml
    ```
<br/>

- Set the desire namespace of helm deployment
    ```bash
    HELM_NAMESPACE=argocd
    ```
<br/>

- Deploy the helm chart
    ```bash
    helm upgrade --install argocd argo/argo-cd --version ${HELM_CHART_VERSION} --create-namespace --namespace ${HELM_NAMESPACE} --values values.yaml
    ```

<br/>

- Uninstall
    ```bash
    helm uninstall argocd
    kubectl delete ns argocd --force
    ```