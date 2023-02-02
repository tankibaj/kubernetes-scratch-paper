# Crash Loop
Simple alpine-based container that sleeps for 5 seconds and then exits. The purpose is to produce a CrashLoopBackOff scenario for the Prometheus alert.


## Kubernetes deployment

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crashme-deployment
  labels:
    app: crashme
spec:
  replicas: 1
  selector:
    matchLabels:
      app: crashme
  template:
    metadata:
      labels:
        app: crashme
    spec:
      containers:
      - name: crashme
        image: thenaim/crashloopbackoff:latest
EOF
```
