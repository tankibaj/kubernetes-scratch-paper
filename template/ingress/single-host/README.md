### Quick start

- Apply manifest

    ```bash
    kubectl apply -f ingress-single-host.yaml
    ```

- Test ingress

    ```bash
    curl -H "Host: ingress.lan" http://HOST_IP
    OR
    curl -H "Host: ingress.lan" http://INGRESS_SERVICE_EXTERNAL_IP
    ```

- Clean up

    ```bash
    kubectl delete -f ingress-single-host.yaml
    ```