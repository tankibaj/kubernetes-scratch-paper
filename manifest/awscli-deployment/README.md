```bash
kubectl apply -f https://raw.githubusercontent.com/tankibaj/kubernetes-scratch-paper/main/manifest/awscli-deployment/awscli-deployment.yaml
```

```bash
POD_ID=$(kubectl get pod -l app=awscli -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD_ID bash
```

```bash
aws sts get-caller-identity
```

```bash
kubectl delete -f https://raw.githubusercontent.com/tankibaj/kubernetes-scratch-paper/main/snippet/awscli-deployment/awscli-deployment.yaml
```