# crash-loop
Simple alpine-based container that sleeps for 5 seconds and then exits. The purpose is to produce a CrashLoopBackOff scenario for the Prometheus alert.

## Build docker image

```bash
docker build -t thenaim/crashloopbackoff .
```

## Kubernetes deployment

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crashloopbackoff-deployment
  labels:
    app: crashloopbackoff
spec:
  replicas: 1
  selector:
    matchLabels:
      app: crashloopbackoff
  template:
    metadata:
      labels:
        app: crashloopbackoff
    spec:
      containers:
      - name: crashloop
        image: thenaim/crashloopbackoff:latest
EOF
```
