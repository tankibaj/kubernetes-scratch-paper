```bash
k apply -f https://raw.githubusercontent.com/tankibaj/kubernetes-scratch-paper/main/snippet/statefulset-with-pvc.yaml
```

```bash
POD_ID=$(kubectl -n test get pod -l app=date-alpine -o jsonpath="{.items[0].metadata.name}")
kubectl -n test exec $POD_ID -- sh -c "cat -n /data/log"
```