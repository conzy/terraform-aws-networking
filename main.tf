data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.7.0"
  name    = "vpc"
  cidr    = var.base_cidr

  # Span two availability zones
  azs = [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1],
  ]
  database_subnets             = [cidrsubnet(var.base_cidr, 7, 0), cidrsubnet(var.base_cidr, 7, 1)]
  public_subnets               = [cidrsubnet(var.base_cidr, 4, 1), cidrsubnet(var.base_cidr, 4, 2)]
  private_subnets              = [cidrsubnet(var.base_cidr, 4, 3), cidrsubnet(var.base_cidr, 4, 4)]
  intra_subnets                = [cidrsubnet(var.base_cidr, 4, 5), cidrsubnet(var.base_cidr, 4, 6)]
  create_database_subnet_group = true
  database_subnet_group_name   = "vpc"

  enable_nat_gateway     = true
  single_nat_gateway     = var.high_availability ? false : true
  one_nat_gateway_per_az = var.high_availability ? true : false

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true

}

# VPC Endpoints

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.7.0"
  vpc_id  = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      tags            = { Name = "s3-vpc-endpoint" }
      route_table_ids = module.vpc.private_route_table_ids
    },
    dynamodb = {
      service      = "dynamodb"
      service_type = "Gateway"
      route_table_ids = flatten([
        module.vpc.intra_route_table_ids,
        module.vpc.private_route_table_ids,
        module.vpc.public_route_table_ids
      ])
      policy = data.aws_iam_policy_document.dynamodb_endpoint_policy.json
      tags   = { Name = "dynamodb-vpc-endpoint" }
    },
  }
}

data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  statement {
    actions   = ["dynamodb:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpc"
      values   = [module.vpc.vpc_id]
    }
  }
}

# Private DNS. This is handy as you will have a known internal DNS in all accounts. You can then create services like
# api.conzy.internal and the DNS will be the same in all environments.

resource "aws_route53_zone" "private" {
  name = "conzy.internal"

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}
