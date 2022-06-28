module "load_balancer_controller" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.18.0"

  role_name                              = "${local.irsa_prefix}-load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}

output "load_balancer_controller_iam_role_arn" {
  description = "IAM role arn of load balancer controller"
  value       = module.load_balancer_controller.iam_role_arn
}