output "vpc_id" {
  value = module.vpc.vpc_id
}

output "database_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "intra_subnets" {
  value = module.vpc.intra_subnets
}

output "database_subnets" {
  value = module.vpc.database_subnets
}