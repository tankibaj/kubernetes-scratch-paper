## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72 |


## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_autoscaler"></a> [cluster\_autoscaler](#module\_cluster\_autoscaler) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 4.18.0 |
| <a name="module_ebs_csi"></a> [ebs\_csi](#module\_ebs\_csi) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 4.18.0 |
| <a name="module_efs_csi"></a> [efs\_csi](#module\_efs\_csi) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 4.18.0 |
| <a name="module_external_dns"></a> [external\_dns](#module\_external\_dns) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 4.18.0 |
| <a name="module_load_balancer_controller"></a> [load\_balancer\_controller](#module\_load\_balancer\_controller) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 4.18.0 |



## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_autoscaler_iam_role_arn"></a> [cluster\_autoscaler\_iam\_role\_arn](#output\_cluster\_autoscaler\_iam\_role\_arn) | IAM role arn of cluster autoscaler |
| <a name="output_ebs_csi_iam_role_arn"></a> [ebs\_csi\_iam\_role\_arn](#output\_ebs\_csi\_iam\_role\_arn) | IAM role arn of ebs csi |
| <a name="output_efs_csi_iam_role_arn"></a> [efs\_csi\_iam\_role\_arn](#output\_efs\_csi\_iam\_role\_arn) | IAM role arn of efs csi |
| <a name="output_external_dns_iam_role_arn"></a> [external\_dns\_iam\_role\_arn](#output\_external\_dns\_iam\_role\_arn) | IAM role arn of external dns |
| <a name="output_load_balancer_controller_iam_role_arn"></a> [load\_balancer\_controller\_iam\_role\_arn](#output\_load\_balancer\_controller\_iam\_role\_arn) | IAM role arn of load balancer controller |