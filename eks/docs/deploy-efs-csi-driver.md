# Deploy EFS CSI Driver on EKS

The Amazon EFS Container Storage Interface (CSI) driver provides a CSI interface that allows Kubernetes clusters running on AWS to manage the lifecycle of Amazon EFS file systems.

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

## Set Environment Variables

```bash
export EKS_POLICY_NAME=AmazonEKS_EFS_CSI_Driver_Policy
export AWS_PROFILE=Demo
export EKS_ACCOUNT_ID=237541186343
export EKS_REGION=eu-central-1
export EKS_CLUSTER_NAME=eks-demo
export FILE_SYSTEM_ID=fs-991e8e036b01e9261
```

<br/>

## Verify Amazon EFS file system

Check the LifeCycleState of the file system using the following command and wait until it changes from creating to available before you proceed to the next step.

```bash
aws efs describe-file-systems --file-system-id $FILE_SYSTEM_ID
```

<br/>

## IRSA (IAM roles for service account)

Enabling IAM roles for service accounts on the cluster

```bash
eksctl utils associate-iam-oidc-provider \
    --region $EKS_REGION \
    --cluster $EKS_CLUSTER_NAME \
    --approve
```

Create an IAM policy that allows the CSI driver's service account to make calls to AWS APIs on your behalf.

```bash
curl -o iam-policy-example.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/v1.3.2/docs/iam-policy-example.json
```

```bash
aws iam create-policy \
    --policy-name $EKS_POLICY_NAME \
    --policy-document file://iam-policy-example.json
```

Create an IAM role for the `efs-csi-controller` Service Account in the `kube-system` namespace.

```bash
eksctl create iamserviceaccount \
    --name efs-csi-controller-sa \
    --namespace kube-system \
    --cluster $EKS_CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::$EKS_ACCOUNT_ID:policy/$EKS_POLICY_NAME \
    --approve \
    --override-existing-serviceaccounts \
    --region $EKS_REGION
```

Create an IAM role for the `efs-csi-node` Service Account in the `kube-system` namespace.

```bash
eksctl create iamserviceaccount \
    --name efs-csi-node-sa \
    --namespace kube-system \
    --cluster $EKS_CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::$EKS_ACCOUNT_ID:policy/$EKS_POLICY_NAME \
    --approve \
    --override-existing-serviceaccounts \
    --region $EKS_REGION
```

Make sure service account with the ARN of the IAM role is annotated

```bash
kubectl -n kube-system describe serviceaccount efs-csi-controller-sa

```

```bash
kubectl -n kube-system describe serviceaccount efs-csi-node-sa
```

Output

```
Name:                efs-csi-controller-sa
Namespace:           kube-system
Labels:              app.kubernetes.io/managed-by=eksctl
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::237541186343:role/eksctl-eks-dh-addon-iamserviceaccount-kube-s-Role1-1FLZKGSD2RR3R
Image pull secrets:  <none>
Mountable secrets:   efs-csi-controller-sa-token-thdzq
Tokens:              efs-csi-controller-sa-token-thdzq
Events:              <none>
```

```bash
Name:                efs-csi-node-sa
Namespace:           kube-system
Labels:              app.kubernetes.io/managed-by=eksctl
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::237541186343:role/eksctl-eks-dh-addon-iamserviceaccount-kube-s-Role1-1OMSJJFMHCAYF
Image pull secrets:  <none>
Mountable secrets:   efs-csi-node-sa-token-xjdxn
Tokens:              efs-csi-node-sa-token-xjdxn
Events:              <none>
```

<br/>

## Deploy Amazon EFS driver

Install the Amazon EFS CSI driver using Helm

```bash
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update
```

```bash
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set replicaCount=1 \
  --set controller.serviceAccount.create=false \
  --set controller.serviceAccount.name=efs-csi-controller-sa \
  --set node.serviceAccount.create=false \
  --set node.serviceAccount.name=efs-csi-node-sa \
  -n kube-system
```

Verify that aws-efs-csi-driver has started

```bash
kubectl get pod -n kube-system -l "app.kubernetes.io/name=aws-efs-csi-driver,app.kubernetes.io/instance=aws-efs-csi-driver"
```

Output

```bash
NAME                                  READY   STATUS    RESTARTS   AGE
efs-csi-controller-6d7dd88b94-9mqlh   3/3     Running   0          4m55s
efs-csi-node-7lq7s                    3/3     Running   0          4m56s
```

<br/>

## Dynamic Provisioning

**Prerequisite:** You must use version 1.2x or later of the Amazon EFS CSI driver, which requires a 1.17 or later cluster. To update your cluster, see [Updating a cluster](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html).

Create a `StorageClass` for Amazon EFS file systems. For all parameters and configuration options, see [Amazon EFS CSI Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver) on GitHub.

```bash
export FILE_SYSTEM_ID=fs-991e8e036b01e9261
```

```bash
cat <<EoF > efs-storageclass.yaml
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${FILE_SYSTEM_ID}
  directoryPerms: "700"
  gidRangeStart: "1000" # optional
  gidRangeEnd: "2000" # optional
  basePath: "/dynamic_provisioning" # optional
EoF
```

```bash
kubectl apply -f efs-storageclass.yaml
```

### Test

Test automatic provisioning by deploying a Pod that makes use of the PersistentVolumeClaim.

```bash
cat <<EoF > pod-with-pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: efs-app
spec:
  containers:
    - name: app
      image: alpine
      command: ["/bin/sh", "-c"]
      args: ["while true; do date >> /data/log; sleep 5; done"]
      volumeMounts:
        - name: persistent-storage
          mountPath: /data
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: efs-claim
EoF
```

```bash
kubectl apply -f pod-with-pvc.yaml
```

Determine the names of the pods running the controller.

```bash
EFS_CONTROLLER_POD_ID=$(kubectl -n kube-system get pod -l app=efs-csi-controller -o jsonpath="{.items[0].metadata.name}")
```

Check whether PVC provisioned or not

```bash
kubectl logs $EFS_CONTROLLER_POD_ID \
    -n kube-system \
    -c csi-provisioner \
    --tail 10
```

Output

```
1 controller.go:838] successfully created PV pvc-f99d4718-9d52-4db7-8f85-127803051a68 for PVC efs-claim and csi volume name fs-6fc57a34::fsap-025acd9bd6fdfd41c
```

Confirm that a persistent volume was created with a status of Bound to a PersistentVolumeClaim:

```bash
kubectl get pv
```

View details about the PersistentVolumeClaim that was created.

```bash
kubectl get pvc
```

View the sample app pod's status.

```bash
kubectl get pods -o wide
```

Confirm that the data is written to the volume.

```bash
kubectl exec efs-app -- sh -c "cat -n data/log"
```

Output

```bash
Thu Oct 28 11:10:05 UTC 2021
Thu Oct 28 11:10:10 UTC 2021
Thu Oct 28 11:10:15 UTC 2021
Thu Oct 28 11:10:20 UTC 2021
Thu Oct 28 11:10:25 UTC 2021
Thu Oct 28 11:10:30 UTC 2021
Thu Oct 28 11:10:35 UTC 2021
```

<br/>

## Change default Storage Class

List the StorageClasses in your cluster:

```bash
kubectl get storageclass
```

Output:

```
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs             efs.csi.aws.com         Delete          Immediate              false                  6m39s
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  25h
```

The `gp2` StorageClass is marked by `(default)`.

Mark the `gp2` StorageClass as non-default. The `gp2` StorageClass has an annotation `storageclass.kubernetes.io/is-default-class` set to `true`. Any other value or absence of the annotation is interpreted as `false`. To mark a StorageClass as non-default, you need to change its value to `false`:

```bash
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

Mark a StorageClass as default. Similar to the previous step, you need to add/set the annotation `storageclass.kubernetes.io/is-default-class=true`.

```bash
kubectl patch storageclass efs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

Please note that at most one StorageClass can be marked as default. If two or more of them are marked as default, a `PersistentVolumeClaim` without `storageClassName` explicitly specified cannot be created.

Verify that your chosen StorageClass is default:

```bash
kubectl get storageclass
```

Output:

```
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs (default)   efs.csi.aws.com         Delete          Immediate              false                  13m
gp2             kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  25h
```

<br/>

## Static Provisioning

This example shows how to make a static provisioned EFS persistent volume (PV) mounted inside container. Edit Persistent Volume code block

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  persistentVolumeReclaimPolicy: Retain
  csi:
    driver: efs.csi.aws.com
    volumeHandle: fs-991e8e036b01e9261 #fs-b83e8ce3:subfolder
```

Replace `VolumeHandle` value with `FileSystemId` of the EFS filesystem that needs to be mounted. You can find it using AWS CLI:

```bash
aws efs describe-file-systems --query "FileSystems[*].FileSystemId"
```

Create PV, PVC and deploy the example application:

```bash
kubectl apply -f example-app.yml
```

Check EFS filesystem is used. After the objects are created, verify that pod is running:

```bash
kubectl get pods
```

Verify data is written into EFS filesystem:

```bash
kubectl exec -ti efs-app -- tail -f /data/out.txt
```

Delete PV and PVC and deploy the example application:

```bash
kubectl delete -f example-app.yml

```




> [https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html)
