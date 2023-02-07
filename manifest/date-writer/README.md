A simple pod with pvc to debug ebs based storageClass.


```bash
kubectl apply -f https://raw.githubusercontent.com/tankibaj/kubernetes-scratch-paper/main/manifest/date-writer/manifest.yaml
```

```bash
kubectl exec date-writer -- sh -c "cat -n /data/out.txt"
```