# ExternalDNS

ExternalDNS makes Kubernetes resources discoverable via public DNS servers. Unlike **[KubeDNS](https://github.com/kubernetes/dns) it's not a DNS server itself, but merely configures other DNS providers accordingly  [AWS Route 53](https://aws.amazon.com/route53/) or [Google Cloud DNS](https://cloud.google.com/dns/docs/). ExternalDNS will automatically ****create a DNS record based on the host specified for the ingress object.

## Set Variables

```bash
export EKS_POLICY_NAME=AmazonEKSExternalDNSPolicy
export AWS_PROFILE=demo
export EKS_ACCOUNT_ID=743586323411
export EKS_REGION=eu-central-1
export EKS_CLUSTER_NAME=eks-demo
```

<br/>

## IAM roles for service account

Enabling IAM roles for service accounts on the cluster

```bash
eksctl utils associate-iam-oidc-provider \
    --region $EKS_REGION \
    --cluster $EKS_CLUSTER_NAME \
    --approve
```

Creating an IAM policy for the service account that allows ExternalDNS to update Route53 record sets

```bash
cat <<EoF > $EKS_POLICY_NAME.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EoF
```

```bash
aws iam create-policy \
    --policy-name $EKS_POLICY_NAME \
    --policy-document file://$EKS_POLICY_NAME.json
```

Finally, create an IAM role for the ExternalDNS service account in the `kube-system` namespace.

```bash
eksctl create iamserviceaccount \
  --cluster=$EKS_CLUSTER_NAME \
  --namespace=kube-system \
  --name=external-dns \
  --attach-policy-arn=arn:aws:iam::$EKS_ACCOUNT_ID:policy/$EKS_POLICY_NAME \
  --override-existing-serviceaccounts \
  --region $EKS_REGION \
  --approve
```

Make sure service account with the ARN of the IAM role is annotated

```bash
kubectl -n kube-system describe serviceaccount external-dns
```

```
Name:                external-dns
Namespace:           kube-system
Labels:              app.kubernetes.io/managed-by=eksctl
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::743586323411:role/eksctl-eks-medicenter-staging-addon-iamservi-Role1-EF5TTFUQIBED
Image pull secrets:  <none>
Mountable secrets:   external-dns-token-8t9df
Tokens:              external-dns-token-8t9df
Events:              <none>
```

<br/>

## Deploy ExternalDNS

Set DNS Zone

```bash
DNS_ZONE=demo.com
```

Create a manifest to deploy ExternalDNS

```bash
cat <<EoF > external-dns.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
rules:
- apiGroups: [""]
  resources: ["services","endpoints","pods"]
  verbs: ["get","watch","list"]
- apiGroups: ["extensions","networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get","watch","list"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: kube-system
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: k8s.gcr.io/external-dns/external-dns:v0.7.6
        args:
        - --source=service
        - --source=ingress
        - --domain-filter=${DNS_ZONE} # will make ExternalDNS see only the hosted zones matching provided domain, omit to process all available hosted zones
        - --provider=aws
        - --policy=upsert-only # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
        - --aws-zone-type=public # only look at public hosted zones (valid values are public, private or no value for both)
        - --registry=txt
        - --txt-owner-id=${EKS_CLUSTER_NAME}
      securityContext:
        fsGroup: 65534 # For ExternalDNS to be able to read Kubernetes and AWS token files
EoF
```


> 💡 Specify `- --domain-filter` multiple times for multiple domains.

```yaml
[...]
containers:
      - name: external-dns
        args:
        - --source=service
        - --source=ingress
        - --domain-filter=domain1.cloud
        - --domain-filter=domain2.net
        - --domain-filter=domain3.zone
        - --provider=aws
        [...]
```

Apply created manifest

```bash
kubectl apply -f external-dns.yaml
```

Check logs

```bash
kubectl logs -n kube-system $(kubectl get po -n kube-system | egrep -o 'external-dns[a-zA-Z0-9-]+')
```

```
........
time="2022-03-15T11:50:04Z" level=info msg="Instantiating new Kubernetes client"
time="2022-03-15T11:50:04Z" level=info msg="Using inCluster-config based on serviceaccount-token"
time="2022-03-15T11:50:04Z" level=info msg="Created Kubernetes client https://10.100.0.1:443"
time="2022-03-15T11:50:13Z" level=info msg="All records are already up to date"
.........
```

<br/>

## Test

Create the following sample application to test that ExternalDNS works.

### Service

> 💡 For services ExternalDNS will look for the annotation `external-dns.alpha.kubernetes.io/hostname` on the service and use the corresponding value.

> 💡 If you want to give multiple names to service, you can set it to [external-dns.alpha.kubernetes.io/hostname](http://external-dns.alpha.kubernetes.io/hostname) with a comma separator.


Set DNS record

```bash
SERVICE_DNS_RECORD=nginx.demo.com
```

Create a sample service and deployment manifest

```bash
cat <<EoF > exdns-sample-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  annotations:
    external-dns.alpha.kubernetes.io/hostname: ${SERVICE_DNS_RECORD}
spec:
  type: LoadBalancer
  ports:
  - port: 80
    name: http
    targetPort: 80
  selector:
    app: nginx

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
          name: http
EoF
```

Apply created manifest

```bash
kubectl apply -f exdns-sample-service.yaml
```

Curl DNS record

```bash
curl $SERVICE_DNS_RECORD
```

Delete test deployment

```bash
kubectl delete -f exdns-sample-service.yaml
```

### Ingress


> 💡 For ingress objects ExternalDNS will create a DNS record based on the host specified for the ingress object

Set DNS record

```bash
INGRESS_DNS_RECORD_1=red.demo.com
INGRESS_DNS_RECORD_2=blue.demo.com
```

Create a sample ingress, service and deployment manifest

```bash
cat <<EoF > exdns-sample-ingress.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: red-deployment
  labels:
    app: red
spec:
  replicas: 1
  selector:
    matchLabels:
      app: red
  template:
    metadata:
      labels:
        app: red
    spec:
      containers:
      - name: red
        image: thenaim/red:latest
        ports:
        - containerPort: 8888

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blue-deployment
  labels:
    app: blue
spec:
  replicas: 1
  selector:
    matchLabels:
      app: blue
  template:
    metadata:
      labels:
        app: blue
    spec:
      containers:
      - name: blue
        image: thenaim/blue:latest
        ports:
        - containerPort: 8888

---
apiVersion: v1
kind: Service
metadata:
  name: red-service
spec:
  selector:
    app: red
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8888

---
apiVersion: v1
kind: Service
metadata:
  name: blue-service
spec:
  selector:
    app: blue
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8888

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: red-blue-ingress
#   namespace: default
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
    alb.ingress.kubernetes.io/certificate-arn: <ACME Certificate ARN>
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
spec:
  rules:
  - host: ${INGRESS_DNS_RECORD_1}
    http:
      paths:
      - pathType: ImplementationSpecific
        path: /*
        backend:
          service:
            name: red-service
            port:
              number: 80
  - host: ${INGRESS_DNS_RECORD_2}
    http:
      paths:
      - pathType: ImplementationSpecific
        path: /*
        backend:
          service:
            name: blue-service
            port:
              number: 80
EoF
```

Apply created manifest

```bash
kubectl apply -f exdns-sample-ingress.yaml
```

Curl DNS record

```bash
curl https://$INGRESS_DNS_RECORD_1
curl https://$INGRESS_DNS_RECORD_2
```

Delete test deployment

```bash
kubectl delete -f exdns-sample-ingress.yaml
```



<br/><br/>

> [external-dns/aws.md at master · kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md)

> [EchoServer - AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/examples/echo_server/#setup-external-dns-to-manage-dns-automatically)
