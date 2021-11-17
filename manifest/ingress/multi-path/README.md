### Quick start

- Apply manifest

    ```bash
    kubectl apply -f ingress-multi-path.yaml
    ```

- Test ingress

    ```bash
    curl -H "Host: ingress.lan" http://HOST_IP
    curl -H "Host: ingress.lan" http://HOST_IP/blue
    curl -H "Host: ingress.lan" http://HOST_IP/green
    OR
    curl -H "Host: ingress.lan" http://INGRESS_SERVICE_EXTERNAL_IP
    ```

- Clean up

    ```bash
    kubectl delete -f ingress-multi-path.yaml
    ```