#module "vpc_cni" {
#  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#  version = "~> 4.18.0"
#
#  role_name             = "${local.irsa_prefix}-vpc-cni"
#  attach_vpc_cni_policy = true
#  vpc_cni_enable_ipv4   = true
#  #  vpc_cni_enable_ipv6   = true
#
#  oidc_providers = {
#    main = {
#      provider_arn               = module.this_eks.oidc_provider_arn
#      namespace_service_accounts = ["kube-system:aws-node"]
#    }
#  }
#
#  tags = local.tags
#}

#output "vpc_cni_iam_role_arn" {
#  value = module.vpc_cni.iam_role_arn
#}