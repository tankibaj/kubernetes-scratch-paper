```bash
kubectl apply -f https://raw.githubusercontent.com/tankibaj/kubernetes-scratch-paper/main/snippet/pod-with-pvc/pod-with-pvc.yaml
```

```bash
kubectl -n test exec test-app -- sh -c "cat -n /data/out.txt"
```

```bash
kubectl delete -f https://raw.githubusercontent.com/tankibaj/kubernetes-scratch-paper/main/snippet/pod-with-pvc/pod-with-pvc.yaml
```