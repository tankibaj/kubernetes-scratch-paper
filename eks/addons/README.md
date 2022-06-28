# EKS Addons

- [aws-ebs-csi-driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [aws-efs-csi-driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver)
- [aws-load-balancer-controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)
- [cluster-autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [external-dns](https://github.com/kubernetes-sigs/external-dns)
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server)

<br/>

## AWS Command Line Interface

The AWS Command Line Interface (CLI) is a unified tool to manage your AWS services.

##### [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

```bash
brew install awscli
```

##### [Configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

```bash
aws configure
```

```text
# Example configuration
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: eu-central-1
Default output format [None]: json
```

<br/>


## Terraform

You must install AWS CLI and configure it with the credentials before you use Terraform to manage AWS resources.

##### [Install Terraform](https://www.terraform.io/downloads)

```bash
brew tap hashicorp/tap
```

```bash
brew install hashicorp/tap/terraform
```
##### [Provision infrastructure](https://www.terraform.io/cli/run)

To initialize a working directory that contains a Terraform configuration

```bash
terraform init
```

To see an execution plan that Terraform will make to your infrastructure based on the current configuration

```bash
terraform plan
```

Executes the actions that proposed in a Terraform plan

```bash
  terraform apply
```



<br/>

## Provision

- [IAM Role For Service Account](irsa)
- [Deploy addon helm chart](helm) 
    > NOTE:: Don't forget to change helm chart values
