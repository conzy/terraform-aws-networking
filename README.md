# terraform-aws-networking

This modules wraps the excellent [community module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
adds some opinionated configuration, internal DNS, VPC Endpoints etc

This really shows the power of Terraform module composition. This module creates over 30 resources

```
Plan: 34 to add, 0 to change, 0 to destroy.
```

You can use it to cookie cutter the same VPC into all of your accounts.

## Nat Gateways

NAT Gateways are required to allow internet access from private subnets. This module creates one per availability zone
to ensure we can still route traffic to the internet in the event of an AZ failure. The `high_availablity` variable
when set to false will just create a single NAT Gateway for the VPC to save costs.

## Endpoints

We create Gateway endpoints to avoid incurring data transfer costs through the NAT Gateway related to S3 and DynamoDB

## Topology

The default base CIDR of this module is `/16` it provides `/23` database subnets and `/20` public, private and intra subnets
giving us ~4096 hosts per subnet per availability zone. We are using relatively large IP allocations because Lambda
functions can consume a lot of IP addresses, and we don't want to risk IP exhaustion.

We span _two_ availability zones, N+1 redundancy is adequate, and the knock on cost of spanning 3 availability zones is higher:

- More NAT Gateways
- More Aurora Cluster nodes to now span 3 AZs making DB charges 3x instead of 2x for HA.
- More inter AZ traffic which is billable

### Database Subnet

The database subnet is the smallest `/23` network and this module provides an RDS DB subnet group in this subnet.

### Public Subnet

Resources deployed in this subnet are automatically assigned an ipv4 address and have direct internet access without
the need for a NAT Gateway etc. The only resources that should be placed here are public Application Load Balancers etc

### Private Subnet

Resources in the private subnet are not assigned a public IP and have no inbound access from the internet, outbound access
is provided by the NAT Gateway. Most resources for internal services should go here.

## Outputs

This module outputs useful info such as subnet IDs, instead of needing to plumb through outputs 1:1 in
whatever root module creates this it probably makes sense to do something like:

```hcl
output "vpc_outputs" {
  value = module.vpc
}
```
