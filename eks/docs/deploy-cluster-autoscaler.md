# Deploy Autoscaling on EKS



## Set Variables

```bash

export EKS_POLICY_NAME=AmazonEKSClusterAutoscalerPolicy
export AWS_PROFILE=demo
export EKS_ACCOUNT_ID=341128635374
export EKS_REGION=eu-central-1
export EKS_CLUSTER_NAME=eks-demo
```

Checkout If the AutoScaling group exists

```bash
aws autoscaling \
    describe-auto-scaling-groups \
    --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='$EKS_CLUSTER_NAME']].[AutoScalingGroupName, MinSize, MaxSize,DesiredCapacity]" \
    --output table
```

<br/>

## IAM roles for service accounts

Enabling IAM roles for service accounts on the cluster

```bash
eksctl utils associate-iam-oidc-provider \
    --region $EKS_REGION \
    --cluster $EKS_CLUSTER_NAME \
    --approve
```

Creating an IAM policy for the service account that will allow CA pod to interact with the autoscaling groups

```bash
cat <<EoF > $EKS_POLICY_NAME.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*",
            "Effect": "Allow"
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

Finally, create an IAM role for the cluster-autoscaler Service Account in the kube-system namespace.

```bash
eksctl create iamserviceaccount \
  --cluster=$EKS_CLUSTER_NAME \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::$EKS_ACCOUNT_ID:policy/$EKS_POLICY_NAME \
  --override-existing-serviceaccounts \
  --region $EKS_REGION \
  --approve
```

Make sure service account with the ARN of the IAM role is annotated

```bash
kubectl -n kube-system describe serviceaccount cluster-autoscaler
```

Output

```bash
Name:                cluster-autoscaler
Namespace:           kube-system
Labels:              app.kubernetes.io/managed-by=eksctl
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::341128635374:role/eksctl-eks-dh-addon-iamserviceaccount-kube-s-Role1-AUSE02MN4PLG
Image pull secrets:  <none>
Mountable secrets:   cluster-autoscaler-token-6flmd
Tokens:              cluster-autoscaler-token-6flmd
Events:              <none>
```

<br/>

## Deploy the Cluster Autoscaler (CA)

Download `cluster-autoscaler-autodiscover.yaml` file

```bash
curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

Copy manifest from example file

```bash
cp cluster-autoscaler-autodiscover.yaml.example cluster-autoscaler-autodiscover.yaml
```

Replace cluster name in autoscaler manifest

```bash
sed -i '' 's|<YOUR CLUSTER NAME>|'$EKS_CLUSTER_NAME'|g' cluster-autoscaler-autodiscover.yaml
```

**~~[SKIP]** Retrieve the latest autoscaler image that matches the EKS cluster~~

```bash
export K8S_VERSION=$(kubectl version --short | grep 'Server Version:' | sed 's/[^0-9.]*\([0-9.]*\).*/\1/' | cut -d. -f1,2)
export AUTOSCALER_VERSION=$(curl -s "https://api.github.com/repos/kubernetes/autoscaler/releases" | grep '"tag_name":' | sed 's/.*-\([0-9][0-9\.]*\).*/\1/' | grep -m1 ${K8S_VERSION})
```

**~~[SKIP]** Replace autoscaler image in autoscaler manifest~~

```bash
sed -i '' 's|1.17.3|'$AUTOSCALER_VERSION'|g' cluster-autoscaler-autodiscover.yaml
```

Deploy Cluster Autoscaler to EKS with the following command

```bash
kubectl apply -f cluster-autoscaler-autodiscover.yaml
```

To prevent CA from removing nodes where its own pod is running, we will add the `cluster-autoscaler.kubernetes.io/safe-to-evict` annotation to its deployment with the following command

```bash
kubectl -n kube-system \
    annotate deployment.apps/cluster-autoscaler \
    cluster-autoscaler.kubernetes.io/safe-to-evict="false"
```

Finally, watch the logs

```bash
kubectl -n kube-system logs -f deployment/cluster-autoscaler
```

<br/>

## Test

Deploy an sample nginx application as a ReplicaSet of 1 Pod

```bash
cat <<EoF> nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-to-scaleout
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        service: nginx
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx-to-scaleout
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 500m
            memory: 512Mi
EoF
```

```bash
kubectl apply -f nginx.yaml
kubectl get deployment/nginx-to-scaleout
```

Let’s scale out the replicaset to 10

```bash
kubectl scale --replicas=10 deployment/nginx-to-scaleout
```

Some pods will be in the Pending state, which triggers the cluster-autoscaler to scale out the EC2 fleet.

```bash
watch kubectl get pods -l app=nginx -o wide
```

```bash
watch kubectl get nodes
```

```bash
kubectl -n kube-system logs -f deployment/cluster-autoscaler
```

**Cleanup**

```bash
kubectl delete -f nginx.yaml
```

<br/>
<br/>

> [https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html](https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html)

> [https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md)
