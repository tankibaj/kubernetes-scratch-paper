```bash
export SERVICE_ACCOUNT_NAME=artifact
```

```bash
cat <<EoF > awscli.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: awscli
  name: awscli
spec:
  replicas: 1
  selector:
    matchLabels:
      app: awscli
  template:
    metadata:
      labels:
        app: awscli
    spec:
      serviceAccountName: ${SERVICE_ACCOUNT_NAME}
      automountServiceAccountToken: true
      containers:
      - image: amazon/aws-cli
        name: aws
        command: ["sleep","10000"]
EoF
```

```bash
kubectl apply -f awscli.yaml
```

```bash
POD_ID=$(kubectl -n $NAMESPACE get pod -l app=awscli -o jsonpath="{.items[0].metadata.name}")
kubectl -n $NAMESPACE exec -it $POD_ID bash
```

```bash
aws sts get-caller-identity
```

```bash
kubectl delete -f awscli.yaml
```