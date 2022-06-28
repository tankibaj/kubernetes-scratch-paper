```bash
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
```

```bash
helm repo update
```

```bash
helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --version 2.7.0 --namespace kube-system --values values.yaml
```