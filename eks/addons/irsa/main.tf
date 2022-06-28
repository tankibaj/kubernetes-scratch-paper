locals {
#  environment       = "development" # Environment name of EKS remote state
  oidc_provider_arn = "arn:aws:iam::111111111111:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/132332dsf9324ncds9423" # data.terraform_remote_state.eks.outputs.oidc_provider_arn
  irsa_prefix       = "irsa" # "${data.terraform_remote_state.eks.outputs.cluster_id}-irsa"
  cluster_id        =  "eks-demo" # data.terraform_remote_state.eks.outputs.cluster_id

  tags = {
    Terraform = true
  }
}

#data "terraform_remote_state" "eks" {
#  backend = "s3"
#  config = {
#    bucket = "terraform-state"
#    key    = "aws/${local.environment}/eks.tfstate"
#    region = "eu-central-1"
#  }
#}