```bash
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
```

```bash
helm upgrade --install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver --version 2.2.4 --namespace kube-system --values values.yaml
```