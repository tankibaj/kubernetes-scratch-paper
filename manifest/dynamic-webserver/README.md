A simple stateful webserver to debug EFS/NFS based storageClass and ingressClass.

```bash
kubectl apply -f https://raw.githubusercontent.com/tankibaj/kubernetes-scratch-paper/main/manifest/dynamic-webserver/manifest.yaml
```

> Note:: Don't forget to change `storageClassName`, `ingressClassName` and `ingress host`