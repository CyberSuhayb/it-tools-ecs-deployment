output "vpc_id" {
  description = "ID of the VPC hosting the application infrastructure"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets used by internet-facing resources"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets used by ECS tasks"
  value       = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  description = "Public DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "acm_certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = module.acm.certificate_arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository storing the application image"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster running the service"
  value       = module.ecs.cluster_name
}

output "app_url" {
  description = "Live application URL"
  value       = "https://${var.domain_name}"
}