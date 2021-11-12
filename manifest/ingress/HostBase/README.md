### Quick start

- Apply manifest

    ```bash
    kubectl apply -f ingress-hostbase.yaml
    ```

- Test ingress

    ```bash
    curl -H "Host: ingress.lan" http://HOST_IP
    ```

- Clean up

    ```bash
    kubectl delete -f ingress-hostbase.yaml
    ```