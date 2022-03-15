# Deploy Ingress Controller (AWS Load Balancer Controller) on EKS

AWS Load Balancer Controller is a controller to help manage Elastic Load Balancers for a Kubernetes cluster.

- It satisfies Kubernetes [Ingress resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) by provisioning [Application Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html).
- It satisfies Kubernetes [Service resources](https://kubernetes.io/docs/concepts/services-networking/service/) by provisioning [Network Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html).



Table of Contents
=================

  * [Set Environment Variables](#set-environment-variables)
  * [Verify Amazon EFS file system](#verify-amazon-efs-file-system)
  * [IRSA (IAM roles for service account)](#irsa-iam-roles-for-service-account)
  * [Deploy Amazon EFS driver](#deploy-amazon-efs-driver)
  * [Dynamic Provisioning](#dynamic-provisioning)
    * [Test](#test)
  * [Change default Storage Class](#change-default-storage-class)
  * [Static Provisioning](#static-provisioning)

<br/>

## Set Variables

```bash
export EKS_POLICY_NAME=AWSLoadBalancerControllerIAMPolicy
export EKS_ADDITIONAL_POLICY_NAME=AWSLoadBalancerControllerAdditionalIAMPolicy
export AWS_PROFILE=demo
export EKS_ACCOUNT_ID=12357486324135
export EKS_REGION=eu-central-1
export EKS_CLUSTER_NAME=eks-demo
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

Create an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf. You can view the [policy document](https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json) on GitHub.

```bash
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json
```

```bash
aws iam create-policy \
    --policy-name $EKS_POLICY_NAME \
    --policy-document file://iam_policy.json
```

Create a IAM role and ServiceAccount

```bash
eksctl create iamserviceaccount \
  --cluster=$EKS_CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$EKS_ACCOUNT_ID:policy/$EKS_POLICY_NAME \
  --override-existing-serviceaccounts \
  --region $EKS_REGION \
  --approve
```

Make sure service account with the ARN of the IAM role is annotated

```bash
kubectl -n kube-system describe serviceaccount aws-load-balancer-controller
```

Output

```bash
Name:                aws-load-balancer-controller
Namespace:           kube-system
Labels:              app.kubernetes.io/managed-by=eksctl
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::12357486324135:role/eksctl-eks-dh-addon-iamserviceaccount-kube-s-Role1-1C8O5Y6N6EL3U
Image pull secrets:  <none>
Mountable secrets:   aws-load-balancer-controller-token-svrqk
Tokens:              aws-load-balancer-controller-token-svrqk
Events:              <none>
```

Add the following IAM policy to the IAM role. The policy allows the AWS Load Balancer Controller access to the resources that were created by the ALB Ingress Controller for Kubernetes

```bash
curl -o iam_policy_v1_to_v2_additional.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy_v1_to_v2_additional.json
```

```bash
aws iam create-policy \
  --policy-name $EKS_ADDITIONAL_POLICY_NAME \
  --policy-document file://iam_policy_v1_to_v2_additional.json
```

Attach the additional IAM policy to the IAM role

```bash
export AmazonEKSClusterAWSLBContrRole=$(kubectl -n kube-system describe serviceaccount aws-load-balancer-controller | grep '[eks.amazonaws.com/role-arn](http://eks.amazonaws.com/role-arn)' | awk '{print $3}' | cut -d "/" -f 2)
```

```bash
aws iam attach-role-policy \
  --role-name $AmazonEKSClusterAWSLBContrRole \
  --policy-arn arn:aws:iam::$EKS_ACCOUNT_ID:policy/$EKS_ADDITIONAL_POLICY_NAME
```

<br/>

## Deploy the AWS Load Balancer Controller

Install the TargetGroupBinding CRDs

```bash
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
```

Verify CRDs

```bash
kubectl get crd
```

Deploy the Helm chart

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

```bash
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  -n kube-system
```

Verify that the controller is installed

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```

Output

```bash
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller   2/2     2            2           81s
```

<br/>

## Test

Deploy Sample Application 

Internet facing

```bash
curl -s https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/examples/2048/2048_full_latest.yaml \
    | sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' \
    | kubectl apply -f -
```

Internal

```bash
curl -s https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/examples/2048/2048_full_latest.yaml \
    | sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' \
    | sed 's=alb.ingress.kubernetes.io/scheme: internet-facing=alb.ingress.kubernetes.io/scheme: internal=g' \
    | kubectl apply -f -
```

After few seconds, verify that the Ingress resource is enabled

```bash
kubectl get ingress/ingress-2048 -n game-2048
```

Output

```bash
NAME           CLASS    HOSTS   ADDRESS                                                                     PORTS   AGE
ingress-2048   <none>   *       k8s-game2048-ingress2-c139c4cc74-738660747.eu-central-1.elb.amazonaws.com   80      83s
```

You can find more information on the ingress with this command

```bash
export GAME_INGRESS_NAME=$(kubectl -n game-2048 get targetgroupbindings -o jsonpath='{.items[].metadata.name}')
kubectl -n game-2048 get targetgroupbindings ${GAME_INGRESS_NAME} -o yaml
```

Output

```bash
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  creationTimestamp: "2021-07-30T09:47:44Z"
  finalizers:
  - elbv2.k8s.aws/resources
  generation: 1
  labels:
    ingress.k8s.aws/stack-name: ingress-2048
    ingress.k8s.aws/stack-namespace: game-2048
  name: k8s-game2048-service2-e63ff884cc
  namespace: game-2048
  resourceVersion: "230025"
  uid: d94977df-2ce7-4516-abad-08a85e0a6be9
spec:
  networking:
    ingress:
    - from:
      - securityGroup:
          groupID: sg-06fdcbfb1d42dde0a
      ports:
      - protocol: TCP
  serviceRef:
    name: service-2048
    port: 80
  targetGroupARN: arn:aws:elasticloadbalancing:eu-central-1:101186014818:targetgroup/k8s-game2048-service2-e63ff884cc/c5f9cc3a5becfc51
  targetType: instance
status:
  observedGeneration: 1
```

Finally, you access your newly deployed 2048 game by clicking the URL generated with these commands

```bash
export NAMESPACE=default
export INGRESS_NAME=ingress-2048
export ALB_DNS=$(kubectl -n $NAMESPACE get ingress/$INGRESS_NAME -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo HTTP: http://$ALB_DNS
echo HTTPS: https://$ALB_DNS
```

**Clean up**

Internet facing

```bash
curl -s https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/examples/2048/2048_full_latest.yaml \
    | sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' \
    | kubectl delete -f -
```

Internal

```bash
curl -s https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/examples/2048/2048_full_latest.yaml \
    | sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' \
    | sed 's=alb.ingress.kubernetes.io/scheme: internet-facing=alb.ingress.kubernetes.io/scheme: internal=g' \
    | kubectl delete -f -
```

<br/>

## Ingress manifest snippet

```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: argocd
  name: argocd-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
    alb.ingress.kubernetes.io/certificate-arn: <ACME Certificate ARN>
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS
spec:
  rules:
    - http:
        paths:
          - path: /*
            pathType: ImplementationSpecific
            backend:
              service:
                name: argocd-server
                port:
                  number: 443
```

<br/>

## Annotation usage

`Service.type: NodePort` = `alb.ingress.kubernetes.io/target-type: instance`

`Service.type: ClusterIP` = `alb.ingress.kubernetes.io/target-type: ip`

[https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html)

> [Github](https://github.com/kubernetes-sigs/aws-load-balancer-controller)

> [Ingress annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/ingress/annotations/)
